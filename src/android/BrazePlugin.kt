package com.braze.cordova

import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import com.braze.enums.*
import com.braze.events.FeedUpdatedEvent
import com.braze.models.outgoing.AttributionData
import com.braze.Braze
import com.braze.BrazeUser
import com.braze.configuration.BrazeConfig
import com.braze.cordova.ContentCardUtils.getCardById
import com.braze.cordova.ContentCardUtils.mapContentCards
import com.braze.cordova.CordovaInAppMessageViewWrapper.CordovaInAppMessageViewWrapperFactory
import com.braze.enums.BrazeSdkMetadata
import com.braze.events.ContentCardsUpdatedEvent
import com.braze.events.IEventSubscriber
import com.braze.models.outgoing.BrazeProperties
import com.braze.support.BrazeLogger.Priority.*
import com.braze.support.BrazeLogger.brazelog
import com.braze.support.BrazeLogger.logLevel
import com.braze.support.requestPushPermissionPrompt
import com.braze.ui.activities.BrazeFeedActivity
import com.braze.ui.activities.ContentCardsActivity
import com.braze.ui.inappmessage.BrazeInAppMessageManager
import org.apache.cordova.CallbackContext
import org.apache.cordova.CordovaPlugin
import org.apache.cordova.CordovaPreferences
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject
import java.math.BigDecimal
import java.util.*
import java.util.concurrent.ConcurrentHashMap

@Suppress("TooManyFunctions", "MaxLineLength", "WildcardImport")
open class BrazePlugin : CordovaPlugin() {
    private lateinit var applicationContext: Context
    private var pluginInitializationFinished = false
    private var disableAutoStartSessions = false
    private val feedSubscriberMap: MutableMap<String, IEventSubscriber<FeedUpdatedEvent>> = ConcurrentHashMap()

    override fun pluginInitialize() {
        applicationContext = cordova.activity.applicationContext

        // Configure Braze using the preferences from the config.xml file passed to our plugin
        configureFromCordovaPreferences(preferences)

        // Since we've likely passed the first Application.onCreate() (due to the plugin lifecycle), lets call the
        // in-app message manager and session handling now
        BrazeInAppMessageManager.getInstance().registerInAppMessageManager(cordova.activity)
        pluginInitializationFinished = true
    }

    private fun runOnBraze(block: (instance: Braze) -> Unit) {
        block(Braze.getInstance(applicationContext))
    }

    private fun runOnUser(block: (currentUser: BrazeUser) -> Unit) {
        Braze.getInstance(applicationContext).getCurrentUser { block(it) }
    }

    @Suppress("ComplexMethod", "LongMethod", "MagicNumber", "ReturnCount")
    override fun execute(action: String, args: JSONArray, callbackContext: CallbackContext): Boolean {
        initializePluginIfAppropriate()
        brazelog(I) { "Received $action with the following arguments: $args" }
        when (action) {
            "startSessionTracking" -> {
                disableAutoStartSessions = false
                return true
            }
            "registerAppboyPushMessages", "setRegisteredPushToken" -> {
                runOnBraze { it.registeredPushToken = args.getString(0) }
                return true
            }
            "changeUser" -> {
                runOnBraze { it.changeUser(args.getString(0)) }
                return true
            }
            "logCustomEvent" -> {
                var properties: BrazeProperties? = null
                if (args[1] !== JSONObject.NULL) {
                    properties = BrazeProperties(args.getJSONObject(1))
                }
                runOnBraze { it.logCustomEvent(args.getString(0), properties) }
                return true
            }
            "logPurchase" -> {
                var currencyCode: String? = "USD"
                if (args[2] !== JSONObject.NULL) {
                    currencyCode = args.getString(2)
                }
                var quantity = 1
                if (args[3] !== JSONObject.NULL) {
                    quantity = args.getInt(3)
                }
                var properties: BrazeProperties? = null
                if (args[4] !== JSONObject.NULL) {
                    properties = BrazeProperties(args.getJSONObject(4))
                }
                runOnBraze {
                    it.logPurchase(
                        productId = args.getString(0),
                        currencyCode = currencyCode,
                        price = BigDecimal(args.getDouble(1)),
                        quantity = quantity,
                        properties = properties
                    )
                }
                return true
            }
            "wipeData" -> {
                Braze.wipeData(applicationContext)
                pluginInitializationFinished = false
                return true
            }
            "enableSdk" -> {
                Braze.enableSdk(applicationContext)
                return true
            }
            "disableSdk" -> {
                Braze.disableSdk(applicationContext)
                pluginInitializationFinished = false
                return true
            }
            "requestImmediateDataFlush" -> {
                runOnBraze { it.requestImmediateDataFlush() }
                return true
            }
            "requestContentCardsRefresh" -> {
                runOnBraze { it.requestContentCardsRefresh(false) }
                return true
            }
            "getDeviceId" -> {
                callbackContext.success(Braze.getInstance(applicationContext).deviceId)
                return true
            }
            "requestPushPermission" -> {
                cordova.activity.requestPushPermissionPrompt()
                return true
            }
            "setUserAttributionData" -> {
                runOnUser {
                    it.setAttributionData(
                        AttributionData(
                            args.getString(0),
                            args.getString(1),
                            args.getString(2),
                            args.getString(3)
                        )
                    )
                }
                return true
            }
            "setStringCustomUserAttribute" -> {
                runOnUser { it.setCustomUserAttribute(args.getString(0), args.getString(1)) }
                return true
            }
            "unsetCustomUserAttribute" -> {
                runOnUser { it.unsetCustomUserAttribute(args.getString(0)) }
                return true
            }
            "setBoolCustomUserAttribute" -> {
                runOnUser { it.setCustomUserAttribute(args.getString(0), args.getBoolean(1)) }
                return true
            }
            "setIntCustomUserAttribute" -> {
                runOnUser { it.setCustomUserAttribute(args.getString(0), args.getInt(1)) }
                return true
            }
            "setDoubleCustomUserAttribute" -> {
                runOnUser { it.setCustomUserAttribute(args.getString(0), args.getDouble(1).toFloat()) }
                return true
            }
            "setDateCustomUserAttribute" -> {
                runOnUser { it.setCustomUserAttributeToSecondsFromEpoch(args.getString(0), args.getLong(1)) }
                return true
            }
            "incrementCustomUserAttribute" -> {
                runOnUser { it.incrementCustomUserAttribute(args.getString(0), args.getInt(1)) }
                return true
            }
            "setCustomUserAttributeArray" -> {
                val attributes = parseJSONArrayToStringArray(args.getJSONArray(1))
                runOnUser { it.setCustomAttributeArray(args.getString(0), attributes) }
                return true
            }
            "addToCustomAttributeArray" -> {
                runOnUser { it.addToCustomAttributeArray(args.getString(0), args.getString(1)) }
                return true
            }
            "removeFromCustomAttributeArray" -> {
                runOnUser { it.removeFromCustomAttributeArray(args.getString(0), args.getString(1)) }
                return true
            }
            "setFirstName" -> {
                runOnUser { it.setFirstName(args.getString(0)) }
                return true
            }
            "setLastName" -> {
                runOnUser { it.setLastName(args.getString(0)) }
                return true
            }
            "setEmail" -> {
                runOnUser { it.setEmail(args.getString(0)) }
                return true
            }
            "setGender" -> {
                val genderString = args.getString(0).lowercase(Locale.US)
                runOnUser { currentUser ->
                    Gender.getGender(genderString)?.let {
                        currentUser.setGender(it)
                    }
                }
                return true
            }
            "addAlias" -> {
                runOnUser { it.addAlias(args.getString(0), args.getString(1)) }
                return true
            }
            "setDateOfBirth" -> {
                runOnUser { currentUser ->
                    Month.getMonth(args.getInt(1) - 1)?.let {
                        currentUser.setDateOfBirth(args.getInt(0), it, args.getInt(2))
                    }
                }
                return true
            }
            "setCountry" -> {
                runOnUser { it.setCountry(args.getString(0)) }
                return true
            }
            "setHomeCity" -> {
                runOnUser { it.setHomeCity(args.getString(0)) }
                return true
            }
            "setPhoneNumber" -> {
                runOnUser { it.setPhoneNumber(args.getString(0)) }
                return true
            }
            "setPushNotificationSubscriptionType" -> {
                runOnUser { currentUser ->
                    NotificationSubscriptionType.fromValue(args.getString(0))?.let {
                        currentUser.setPushNotificationSubscriptionType(it)
                    }
                }
                return true
            }
            "setEmailNotificationSubscriptionType" -> {
                runOnUser { currentUser ->
                    NotificationSubscriptionType.fromValue(args.getString(0))?.let {
                        currentUser.setEmailNotificationSubscriptionType(it)
                    }
                }
                return true
            }
            "setLanguage" -> {
                runOnUser { it.setLanguage(args.getString(0)) }
                return true
            }
            "addToSubscriptionGroup" -> {
                runOnUser { it.addToSubscriptionGroup(args.getString(0)) }
                return true
            }
            "removeFromSubscriptionGroup" -> {
                runOnUser { it.removeFromSubscriptionGroup(args.getString(0)) }
                return true
            }
            "launchNewsFeed" -> {
                val intent = Intent(applicationContext, BrazeFeedActivity::class.java)
                cordova.activity.startActivity(intent)
                return true
            }
            "launchContentCards" -> {
                val intent = Intent(applicationContext, ContentCardsActivity::class.java)
                cordova.activity.startActivity(intent)
                return true
            }
            GET_NEWS_FEED_METHOD,
            GET_CARD_COUNT_FOR_CATEGORIES_METHOD,
            GET_UNREAD_CARD_COUNT_FOR_CATEGORIES_METHOD -> return handleNewsFeedGetters(action, args, callbackContext)
            GET_CONTENT_CARDS_FROM_SERVER_METHOD,
            GET_CONTENT_CARDS_FROM_CACHE_METHOD -> return handleContentCardsUpdateGetters(action, callbackContext)
            LOG_CONTENT_CARDS_CLICKED_METHOD,
            LOG_CONTENT_CARDS_DISMISSED_METHOD,
            LOG_CONTENT_CARDS_IMPRESSION_METHOD -> return handleContentCardsLogMethods(action, args, callbackContext)
        }
        brazelog(D) { "Failed to execute for action: $action" }
        return false
    }

    override fun onPause(multitasking: Boolean) {
        super.onPause(multitasking)
        initializePluginIfAppropriate()
        BrazeInAppMessageManager.getInstance().unregisterInAppMessageManager(cordova.activity)
    }

    override fun onResume(multitasking: Boolean) {
        super.onResume(multitasking)
        initializePluginIfAppropriate()
        // Registers the BrazeInAppMessageManager for the current Activity. This Activity will now listen for
        // in-app messages from Braze.
        BrazeInAppMessageManager.getInstance().registerInAppMessageManager(cordova.activity)
    }

    override fun onStart() {
        super.onStart()
        initializePluginIfAppropriate()
        if (!disableAutoStartSessions) {
            Braze.getInstance(applicationContext).openSession(cordova.activity)
        }
    }

    override fun onStop() {
        super.onStop()
        initializePluginIfAppropriate()
        if (!disableAutoStartSessions) {
            Braze.getInstance(applicationContext).closeSession(cordova.activity)
        }
    }

    /**
     * Calls [BrazePlugin.pluginInitialize] if [BrazePlugin.pluginInitializationFinished] is false.
     */
    private fun initializePluginIfAppropriate() {
        if (!pluginInitializationFinished) {
            pluginInitialize()
        }
    }

    /**
     * Calls [Braze.configure] using the values found from the [CordovaPreferences].
     *
     * @param cordovaPreferences the preferences used to initialize this plugin
     */
    @Suppress("ComplexMethod")
    private fun configureFromCordovaPreferences(cordovaPreferences: CordovaPreferences) {
        brazelog { "Setting Cordova preferences: ${cordovaPreferences.all}" }

        // Set the log level
        if (cordovaPreferences.contains(APPBOY_LOG_LEVEL_PREFERENCE)) {
            logLevel = cordovaPreferences.getInteger(APPBOY_LOG_LEVEL_PREFERENCE, Log.INFO)
        }

        // Disable auto starting sessions
        if (cordovaPreferences.getBoolean(DISABLE_AUTO_START_SESSIONS_PREFERENCE, false)) {
            brazelog { "Disabling session auto starts" }
            disableAutoStartSessions = true
        }

        // Set the values used in the config builder
        val configBuilder = BrazeConfig.Builder()

        // Set the flavor
        configBuilder.setSdkFlavor(SdkFlavor.CORDOVA)
            .setSdkMetadata(EnumSet.of(BrazeSdkMetadata.CORDOVA))
        if (cordovaPreferences.contains(APPBOY_API_KEY_PREFERENCE)) {
            configBuilder.setApiKey(cordovaPreferences.getString(APPBOY_API_KEY_PREFERENCE, null))
        }
        if (cordovaPreferences.contains(SMALL_NOTIFICATION_ICON_PREFERENCE)) {
            configBuilder.setSmallNotificationIcon(cordovaPreferences.getString(SMALL_NOTIFICATION_ICON_PREFERENCE, null))
        }
        if (cordovaPreferences.contains(LARGE_NOTIFICATION_ICON_PREFERENCE)) {
            configBuilder.setLargeNotificationIcon(cordovaPreferences.getString(LARGE_NOTIFICATION_ICON_PREFERENCE, null))
        }
        if (cordovaPreferences.contains(DEFAULT_NOTIFICATION_ACCENT_COLOR_PREFERENCE)) {
            configBuilder.setDefaultNotificationAccentColor(parseNumericPreferenceAsInteger(cordovaPreferences.getString(DEFAULT_NOTIFICATION_ACCENT_COLOR_PREFERENCE, "0")))
        }
        if (cordovaPreferences.contains(DEFAULT_SESSION_TIMEOUT_PREFERENCE)) {
            configBuilder.setSessionTimeout(parseNumericPreferenceAsInteger(cordovaPreferences.getString(DEFAULT_SESSION_TIMEOUT_PREFERENCE, "10")))
        }
        if (cordovaPreferences.contains(SET_HANDLE_PUSH_DEEP_LINKS_AUTOMATICALLY_PREFERENCE)) {
            configBuilder.setHandlePushDeepLinksAutomatically(cordovaPreferences.getBoolean(SET_HANDLE_PUSH_DEEP_LINKS_AUTOMATICALLY_PREFERENCE, true))
        }
        if (cordovaPreferences.contains(AUTOMATIC_FIREBASE_PUSH_REGISTRATION_ENABLED_PREFERENCE)) {
            configBuilder.setIsFirebaseCloudMessagingRegistrationEnabled(cordovaPreferences.getBoolean(AUTOMATIC_FIREBASE_PUSH_REGISTRATION_ENABLED_PREFERENCE, true))
        }
        if (cordovaPreferences.contains(FCM_SENDER_ID_PREFERENCE)) {
            parseNumericPreferenceAsString(cordovaPreferences.getString(FCM_SENDER_ID_PREFERENCE, null))?.let { firebaseSenderId ->
                configBuilder.setFirebaseCloudMessagingSenderIdKey(firebaseSenderId)
            }
        }
        if (cordovaPreferences.contains(ENABLE_LOCATION_PREFERENCE)) {
            configBuilder.setIsLocationCollectionEnabled(cordovaPreferences.getBoolean(ENABLE_LOCATION_PREFERENCE, false))
        }
        if (cordovaPreferences.contains(ENABLE_GEOFENCES_PREFERENCE)) {
            configBuilder.setGeofencesEnabled(cordovaPreferences.getBoolean(ENABLE_GEOFENCES_PREFERENCE, false))
        }
        if (cordovaPreferences.contains(CUSTOM_API_ENDPOINT_PREFERENCE)) {
            val customApiEndpoint = cordovaPreferences.getString(CUSTOM_API_ENDPOINT_PREFERENCE, "")
            if (customApiEndpoint != "") {
                configBuilder.setCustomEndpoint(customApiEndpoint)
            }
        }
        val enableRequestFocusFix = cordovaPreferences.getBoolean(ENABLE_CORDOVA_WEBVIEW_REQUEST_FOCUS_FIX_PREFERENCE, true)
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P && enableRequestFocusFix) {
            // Addresses Cordova bug in https://issuetracker.google.com/issues/36915710
            BrazeInAppMessageManager.getInstance().setCustomInAppMessageViewWrapperFactory(CordovaInAppMessageViewWrapperFactory())
        }
        Braze.configure(applicationContext, configBuilder.build())
    }

    private fun handleNewsFeedGetters(action: String, args: JSONArray, callbackContext: CallbackContext): Boolean {
        var feedUpdatedSubscriber: IEventSubscriber<FeedUpdatedEvent>? = null
        var requestingFeedUpdateFromCache = false
        val braze = Braze.getInstance(applicationContext)
        val callbackId = callbackContext.callbackId
        when (action) {
            GET_CARD_COUNT_FOR_CATEGORIES_METHOD -> {
                val categories = getCategoriesFromJSONArray(args)
                feedUpdatedSubscriber = IEventSubscriber { event: FeedUpdatedEvent ->
                    // Each callback context is by default made to only be called once and is afterwards "finished". We want to ensure
                    // that we never try to call the same callback twice. This could happen since we don't know the ordering of the feed
                    // subscription callbacks from the cache.
                    if (!callbackContext.isFinished) {
                        callbackContext.success(event.getCardCount(categories))
                    }

                    // Remove this listener from the map
                    braze.removeSingleSubscription(feedSubscriberMap[callbackId], FeedUpdatedEvent::class.java)
                    feedSubscriberMap.remove(callbackId)
                }
                requestingFeedUpdateFromCache = true
            }
            GET_UNREAD_CARD_COUNT_FOR_CATEGORIES_METHOD -> {
                val categories = getCategoriesFromJSONArray(args)
                feedUpdatedSubscriber = IEventSubscriber { event: FeedUpdatedEvent ->
                    if (!callbackContext.isFinished) {
                        callbackContext.success(event.getUnreadCardCount(categories))
                    }

                    // Remove this listener from the map
                    braze.removeSingleSubscription(feedSubscriberMap[callbackId], FeedUpdatedEvent::class.java)
                    feedSubscriberMap.remove(callbackId)
                }
                requestingFeedUpdateFromCache = true
            }
            GET_NEWS_FEED_METHOD -> {
                val categories = getCategoriesFromJSONArray(args)
                feedUpdatedSubscriber = IEventSubscriber { event: FeedUpdatedEvent ->
                    if (!callbackContext.isFinished) {
                        val cards = event.getFeedCards(categories)
                        val result = JSONArray()
                        var i = 0
                        while (i < cards.size) {
                            result.put(cards[i].forJsonPut())
                            i++
                        }
                        callbackContext.success(result)
                    }

                    // Remove this listener from the map
                    braze.removeSingleSubscription(feedSubscriberMap[callbackId], FeedUpdatedEvent::class.java)
                    feedSubscriberMap.remove(callbackId)
                }
                requestingFeedUpdateFromCache = false
            }
        }
        if (feedUpdatedSubscriber != null) {
            // Put the subscriber into a map so we can remove it later from future subscriptions
            feedSubscriberMap[callbackId] = feedUpdatedSubscriber
            braze.subscribeToFeedUpdates(feedUpdatedSubscriber)
            if (requestingFeedUpdateFromCache) {
                braze.requestFeedRefreshFromCache()
            } else {
                braze.requestFeedRefresh()
            }
        }
        return true
    }

    private fun handleContentCardsUpdateGetters(action: String, callbackContext: CallbackContext): Boolean {
        // Setup a one-time subscriber for the update event
        val subscriber: IEventSubscriber<ContentCardsUpdatedEvent> = object : IEventSubscriber<ContentCardsUpdatedEvent> {
            override fun trigger(message: ContentCardsUpdatedEvent) {
                runOnBraze { it.removeSingleSubscription(this, ContentCardsUpdatedEvent::class.java) }

                // Map the content cards to JSON and return to the client
                callbackContext.success(mapContentCards(message.allCards))
            }
        }

        Braze.getInstance(applicationContext).subscribeToContentCardsUpdates(subscriber)
        Braze.getInstance(applicationContext).requestContentCardsRefresh(
            fromCache = action == GET_CONTENT_CARDS_FROM_CACHE_METHOD
        )
        return true
    }

    @Suppress("ReturnCount")
    private fun handleContentCardsLogMethods(action: String, args: JSONArray, callbackContext: CallbackContext): Boolean {
        val braze = Braze.getInstance(applicationContext)
        if (args.length() != 1) {
            brazelog { "Cannot handle logging method for $action due to improper number of arguments. Args: $args" }
            callbackContext.error("Failed for action $action")
            return false
        }
        val cardId: String = try {
            args.getString(0)
        } catch (e: JSONException) {
            brazelog(E, e) { "Failed to parse card id from args: $args" }
            callbackContext.error("Failed for action $action")
            return false
        }

        // Get the list of cards
        // Only obtaining the current list of cached cards is ok since
        // no id passed in could refer to a card on the server that isn't
        // contained in the list of cached cards
        val cachedContentCards = braze.getCachedContentCards()

        // Get the desired card by its id
        val desiredCard = getCardById(cachedContentCards, cardId)
        if (desiredCard == null) {
            brazelog(W) { "Couldn't find card in list of cached cards" }
            callbackContext.error("Failed for action $action")
            return false
        }
        when (action) {
            LOG_CONTENT_CARDS_CLICKED_METHOD -> desiredCard.logClick()
            LOG_CONTENT_CARDS_DISMISSED_METHOD -> desiredCard.isDismissed = true
            LOG_CONTENT_CARDS_IMPRESSION_METHOD -> desiredCard.logImpression()
        }

        // Return success to the callback
        callbackContext.success()
        return true
    }

    companion object {
        // Preference keys found in the config.xml
        private const val APPBOY_API_KEY_PREFERENCE = "com.appboy.api_key"
        private const val AUTOMATIC_FIREBASE_PUSH_REGISTRATION_ENABLED_PREFERENCE = "com.appboy.firebase_cloud_messaging_registration_enabled"
        private const val FCM_SENDER_ID_PREFERENCE = "com.appboy.android_fcm_sender_id"
        private const val APPBOY_LOG_LEVEL_PREFERENCE = "com.appboy.android_log_level"
        private const val SMALL_NOTIFICATION_ICON_PREFERENCE = "com.appboy.android_small_notification_icon"
        private const val LARGE_NOTIFICATION_ICON_PREFERENCE = "com.appboy.android_large_notification_icon"
        private const val DEFAULT_NOTIFICATION_ACCENT_COLOR_PREFERENCE = "com.appboy.android_notification_accent_color"
        private const val DEFAULT_SESSION_TIMEOUT_PREFERENCE = "com.appboy.android_default_session_timeout"
        private const val SET_HANDLE_PUSH_DEEP_LINKS_AUTOMATICALLY_PREFERENCE = "com.appboy.android_handle_push_deep_links_automatically"
        private const val CUSTOM_API_ENDPOINT_PREFERENCE = "com.appboy.android_api_endpoint"
        private const val ENABLE_LOCATION_PREFERENCE = "com.appboy.enable_location_collection"
        private const val ENABLE_GEOFENCES_PREFERENCE = "com.appboy.geofences_enabled"
        private const val DISABLE_AUTO_START_SESSIONS_PREFERENCE = "com.appboy.android_disable_auto_session_tracking"

        /**
         * When applied, restricts the SDK from taking
         * focus away from the Cordova WebView on affected API versions.
         */
        private const val ENABLE_CORDOVA_WEBVIEW_REQUEST_FOCUS_FIX_PREFERENCE = "com.braze.android_apply_cordova_webview_focus_request_fix"

        // Numeric preference prefix
        private const val NUMERIC_PREFERENCE_PREFIX = "str_"

        // News Feed method names
        private const val GET_NEWS_FEED_METHOD = "getNewsFeed"
        private const val GET_CARD_COUNT_FOR_CATEGORIES_METHOD = "getCardCountForCategories"
        private const val GET_UNREAD_CARD_COUNT_FOR_CATEGORIES_METHOD = "getUnreadCardCountForCategories"

        // Content Card method names
        private const val GET_CONTENT_CARDS_FROM_SERVER_METHOD = "getContentCardsFromServer"
        private const val GET_CONTENT_CARDS_FROM_CACHE_METHOD = "getContentCardsFromCache"
        private const val LOG_CONTENT_CARDS_CLICKED_METHOD = "logContentCardClicked"
        private const val LOG_CONTENT_CARDS_IMPRESSION_METHOD = "logContentCardImpression"
        private const val LOG_CONTENT_CARDS_DISMISSED_METHOD = "logContentCardDismissed"

        private fun getCategoriesFromJSONArray(jsonArray: JSONArray): EnumSet<CardCategory> {
            val categories = EnumSet.noneOf(CardCategory::class.java)
            for (i in 0 until jsonArray.length()) {
                val category = jsonArray.getString(i)
                val categoryArgument: CardCategory? = if (category == "all") {
                    // "All categories" maps to a enumset and not a specific enum so we have to return that here
                    return CardCategory.getAllCategories()
                } else {
                    CardCategory.get(category)
                }
                if (categoryArgument != null) {
                    categories.add(categoryArgument)
                } else {
                    brazelog(W) { "Tried to add unknown card category: $category" }
                }
            }
            return categories
        }

        private fun parseJSONArrayToStringArray(jsonArray: JSONArray): Array<String?> {
            val length = jsonArray.length()
            val array = arrayOfNulls<String>(length)
            for (i in 0 until length) {
                array[i] = jsonArray.getString(i)
            }
            return array
        }

        /**
         * Parses the preference that is optionally prefixed with a constant.
         *
         * I.e. {"PREFIX-value", "value"} -> {"value"}
         */
        private fun parseNumericPreferenceAsString(preference: String?): String? {
            if (preference != null && preference.startsWith(NUMERIC_PREFERENCE_PREFIX)) {
                val preferenceValue = preference.substring(NUMERIC_PREFERENCE_PREFIX.length, preference.length)
                brazelog { "Parsed numeric preference $preference into value: $preferenceValue" }
                return preferenceValue
            }
            return preference
        }

        /**
         * Parses the preference that is optionally prefixed with a constant.
         *
         * I.e. {"PREFIX-value", "value"} -> {"value"}
         */
        private fun parseNumericPreferenceAsInteger(preference: String?): Int {
            var preferenceValue = preference
            if (preference != null && preference.startsWith(NUMERIC_PREFERENCE_PREFIX)) {
                preferenceValue = preference.substring(NUMERIC_PREFERENCE_PREFIX.length, preference.length)
                brazelog { "Parsed numeric preference $preference into value: $preferenceValue" }
            }

            // Parse the string as an integer.
            return preferenceValue?.toInt() ?: -1
        }
    }
}
