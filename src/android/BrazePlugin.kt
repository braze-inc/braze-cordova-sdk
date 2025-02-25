package com.braze.cordova

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import com.braze.Braze
import com.braze.BrazeUser
import com.braze.configuration.BrazeConfig
import com.braze.cordova.ContentCardUtils.getCardById
import com.braze.cordova.ContentCardUtils.mapContentCards
import com.braze.cordova.CordovaInAppMessageViewWrapper.CordovaInAppMessageViewWrapperFactory
import com.braze.cordova.FeatureFlagUtils.mapFeatureFlags
import com.braze.enums.*
import com.braze.enums.inappmessage.ClickAction
import com.braze.events.ContentCardsUpdatedEvent
import com.braze.events.FeatureFlagsUpdatedEvent
import com.braze.events.FeedUpdatedEvent
import com.braze.events.IEventSubscriber
import com.braze.models.inappmessage.IInAppMessage
import com.braze.models.inappmessage.IInAppMessageImmersive
import com.braze.models.inappmessage.InAppMessageBase
import com.braze.models.inappmessage.InAppMessageImmersiveBase
import com.braze.models.inappmessage.MessageButton
import com.braze.models.outgoing.AttributionData
import com.braze.models.outgoing.BrazeProperties
import com.braze.support.BrazeLogger.Priority.*
import com.braze.support.BrazeLogger.brazelog
import com.braze.support.BrazeLogger.logLevel
import com.braze.support.requestPushPermissionPrompt
import com.braze.support.toBundle
import com.braze.ui.BrazeDeeplinkHandler
import com.braze.ui.actions.NewsfeedAction
import com.braze.ui.activities.BrazeFeedActivity
import com.braze.ui.activities.ContentCardsActivity
import com.braze.ui.inappmessage.BrazeInAppMessageManager
import com.braze.ui.inappmessage.InAppMessageOperation
import com.braze.ui.inappmessage.listeners.DefaultInAppMessageManagerListener
import java.math.BigDecimal
import java.util.*
import java.util.concurrent.ConcurrentHashMap
import org.apache.cordova.CallbackContext
import org.apache.cordova.CordovaPlugin
import org.apache.cordova.CordovaPreferences
import org.apache.cordova.PluginResult
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject

@Suppress("TooManyFunctions", "MaxLineLength", "WildcardImport")
open class BrazePlugin : CordovaPlugin() {
    private lateinit var applicationContext: Context
    private var pluginInitializationFinished = false
    private var disableAutoStartSessions = false
    private val feedSubscriberMap: MutableMap<String, IEventSubscriber<FeedUpdatedEvent>> =
            ConcurrentHashMap()
    private var inAppMessageDisplayOperation: InAppMessageOperation =
            InAppMessageOperation.DISPLAY_NOW

    override fun pluginInitialize() {
        applicationContext = cordova.activity.applicationContext

        // Configure Braze using the preferences from the config.xml file passed to our plugin
        configureFromCordovaPreferences(preferences)

        initializeGeofences()
        // Since we've likely passed the first Application.onCreate() (due to the plugin lifecycle),
        // lets call the
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
    override fun execute(
            action: String,
            args: JSONArray,
            callbackContext: CallbackContext
    ): Boolean {
        initializePluginIfAppropriate()
        brazelog(I) { "Received $action with the following arguments: $args" }
        when (action) {
            "startSessionTracking" -> {
                disableAutoStartSessions = false
                return true
            }
            "setRegisteredPushToken" -> {
                runOnBraze { it.registeredPushToken = args.getString(0) }
                return true
            }
            "changeUser" -> {
                val userId = args.getString(0)
                // Pass along the SDK Auth token if provided
                val sdkAuthToken = args.optString(1)
                runOnBraze { it.changeUser(userId, sdkAuthToken) }
                return true
            }
            "getUserId" -> {
                runOnUser { 
                    if (it.userId.isNullOrBlank()) {
                        callbackContext.sendCordovaSuccessPluginResultAsNull()
                    } else {
                        callbackContext.success(it.userId)
                    }
                }
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
            "updateTrackingPropertyAllowList" -> {
                // iOS Only
            }
            "setAdTrackingEnabled" -> {
                runOnBraze { it.setGoogleAdvertisingId(args.getString(1), args.getBoolean(0)) }
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
                runOnUser {
                    it.setCustomUserAttribute(args.getString(0), args.getDouble(1).toFloat())
                }
                return true
            }
            "setDateCustomUserAttribute" -> {
                runOnUser {
                    it.setCustomUserAttributeToSecondsFromEpoch(args.getString(0), args.getLong(1))
                }
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
            "setCustomUserAttributeObjectArray" -> {
                val attributes = parseJSONArraytoJsonObjectArray(args.getJSONArray(1))
                runOnUser { it.setCustomAttribute(args.getString(0), attributes) }
                return true
            }
            "setCustomUserAttributeObject" -> {
                val attributes = args.getJSONObject(1)
                runOnUser {
                    it.setCustomAttribute(args.getString(0), attributes, args.getBoolean(2))
                }
                return true
            }
            "addToCustomAttributeArray" -> {
                runOnUser { it.addToCustomAttributeArray(args.getString(0), args.getString(1)) }
                return true
            }
            "removeFromCustomAttributeArray" -> {
                runOnUser {
                    it.removeFromCustomAttributeArray(args.getString(0), args.getString(1))
                }
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
                    Gender.getGender(genderString)?.let { currentUser.setGender(it) }
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
            "setLastKnownLocation" -> {
                runOnUser {
                    val newArgs = parseJSONArraytoDoubleArray(args)
                    val latitude = newArgs[0]
                    val longitude = newArgs[1]
                    val altitude = newArgs[2]
                    val horizontalAccuracy = newArgs[3]
                    val verticalAccuracy = newArgs[4]

                    if (latitude == null || longitude == null) {
                        brazelog(I) {
                            "Invalid location information with the latitude: $latitude, longitude: $longitude"
                        }
                    } else if (!(latitude > -90 &&
                                    latitude < 90 &&
                                    longitude > -180 &&
                                    longitude < 180)
                    ) {
                        brazelog(I) {
                            "Location information out of bounds. Latitude and longitude values are bounded by ±90 and ±180 respectively."
                        }
                    } else {
                        it.setLastKnownLocation(
                                latitude,
                                longitude,
                                altitude,
                                horizontalAccuracy,
                                verticalAccuracy
                        )
                        brazelog(I) {
                            "Last known location manually set with values: [$latitude, $longitude, $altitude, $horizontalAccuracy, $verticalAccuracy]"
                        }
                    }
                }
                return true
            }
            "setLocationCustomAttribute" -> {
                runOnUser {
                    val newArgs = parseJSONArraytoDoubleArray(args)
                    val key = args.getString(0)
                    val latitude = newArgs[1]
                    val longitude = newArgs[2]

                    if (latitude == null || longitude == null) {
                        brazelog (I) { "Invalid location information with the latitude: $latitude, longitude: $longitude" }
                    } else {
                        it.setLocationCustomAttribute(key, latitude, longitude)
                        brazelog (I) { "Location custom attribute set with key: $key, latitude: $latitude, longitude: $longitude"}
                    }
                }
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
            "subscribeToInAppMessage" -> {
                runOnBraze {
                    val useBrazeUI = args.getBoolean(0)
                    inAppMessageDisplayOperation = if (useBrazeUI) {
                        InAppMessageOperation.DISPLAY_NOW
                    } else {
                        InAppMessageOperation.DISCARD
                    }
                    setDefaultInAppMessageListener()
                }
            }
            "hideCurrentInAppMessage" -> {
                BrazeInAppMessageManager.getInstance().hideCurrentlyDisplayingInAppMessage(true)
            }
            "logInAppMessageImpression" -> {
                runOnBraze {
                    val inAppMessageString = args.getString(0)
                    brazelog { "logInAppMessageImpression called with value $inAppMessageString" }
                    it.deserializeInAppMessageString(inAppMessageString)?.logImpression()
                }
                return true
            }
            "logInAppMessageClicked" -> {
                runOnBraze {
                    val inAppMessageString = args.getString(0)
                    brazelog { "logInAppMessageClicked called with value $inAppMessageString" }
                    it.deserializeInAppMessageString(inAppMessageString)?.logClick()
                }
                return true
            }
            "logInAppMessageButtonClicked" -> {
                runOnBraze { braze ->
                    val inAppMessageString = args.getString(0)
                    val buttonId = args.getInt(1)
                    brazelog {
                        "logInAppMessageButtonClicked called with value $inAppMessageString, and button: $buttonId"
                    }
                    val inAppMessage = braze.deserializeInAppMessageString(inAppMessageString)
                    if (inAppMessage is IInAppMessageImmersive) {
                        inAppMessage.messageButtons.firstOrNull { it.id == buttonId }?.let {
                            inAppMessage.logButtonClick(it)
                        }
                    }
                }
                return true
            }
            "performInAppMessageAction" -> {
                val inAppMessageString = args.getString(0)
                val buttonId = args.getInt(1)
                runOnBraze { braze ->
                    brazelog {
                        "performInAppMessageAction called with value $inAppMessageString, and button: $buttonId"
                    }
                    braze.deserializeInAppMessageString(inAppMessageString)?.let { inAppMessage ->
                        val activity = cordova.activity
                        if (activity == null || inAppMessage !is InAppMessageBase) return@runOnBraze

                        var button: MessageButton? = null
                        if (buttonId >= 0 && inAppMessage is InAppMessageImmersiveBase) {
                            button = inAppMessage.messageButtons.firstOrNull { it.id == buttonId }
                        }
                        val clickAction =
                                if (buttonId < 0) {
                                    inAppMessage.clickAction
                                } else {
                                    button?.clickAction
                                }
                        val clickUri =
                                if (buttonId < 0) {
                                    inAppMessage.uri
                                } else {
                                    button?.uri
                                }
                        val openUriInWebView =
                                if (buttonId < 0) {
                                    inAppMessage.openUriInWebView
                                } else {
                                    button?.openUriInWebview ?: false
                                }
                        brazelog { "got action: $clickUri, $openUriInWebView, $clickAction" }
                        when (clickAction) {
                            ClickAction.NEWS_FEED -> {
                                val newsfeedAction =
                                        NewsfeedAction(
                                                inAppMessage.extras.toBundle(),
                                                Channel.INAPP_MESSAGE
                                        )
                                BrazeDeeplinkHandler.getInstance()
                                        .gotoNewsFeed(activity, newsfeedAction)
                            }
                            ClickAction.URI -> {
                                if (clickUri != null) {
                                    val uriAction =
                                            BrazeDeeplinkHandler.getInstance()
                                                    .createUriActionFromUri(
                                                            clickUri,
                                                            inAppMessage.extras.toBundle(),
                                                            openUriInWebView,
                                                            Channel.INAPP_MESSAGE
                                                    )
                                    brazelog { "Performing gotoUri $clickUri $openUriInWebView" }
                                    BrazeDeeplinkHandler.getInstance()
                                            .gotoUri(applicationContext, uriAction)
                                }
                            }
                            else -> {
                                brazelog { "Unhandled action $clickAction" }
                            }
                        }
                    }
                }
                return true
            }
            "getFeatureFlag" -> {
                runOnBraze {
                    val result = it.getFeatureFlag(args.getString(0))
                    if (result == null) {
                        callbackContext.sendCordovaSuccessPluginResultAsNull()
                    } else {
                        callbackContext.sendPluginResult(
                                PluginResult(PluginResult.Status.OK, result.forJsonPut())
                        )
                    }
                }
                return true
            }
            "getAllFeatureFlags" -> {
                callbackContext.success(
                        mapFeatureFlags(Braze.getInstance(applicationContext).getAllFeatureFlags())
                )
                return true
            }
            "refreshFeatureFlags" -> {
                runOnBraze { it.refreshFeatureFlags() }
                return true
            }
            "subscribeToFeatureFlagUpdates" -> {
                runOnBraze {
                    it.subscribeToFeatureFlagsUpdates { event: FeatureFlagsUpdatedEvent ->
                        val result =
                                PluginResult(
                                        PluginResult.Status.OK,
                                        mapFeatureFlags(event.featureFlags)
                                )
                        result.keepCallback = true
                        callbackContext.sendPluginResult(result)
                    }
                }
                return true
            }
            "getFeatureFlagBooleanProperty" -> {
                runOnBraze {
                    val flagId = args.getString(0)
                    val propKey = args.getString(1)
                    val result = it.getFeatureFlag(flagId)?.getBooleanProperty(propKey)
                    if (result == null) {
                        callbackContext.sendCordovaSuccessPluginResultAsNull()
                    } else {
                        callbackContext.sendPluginResult(
                                PluginResult(PluginResult.Status.OK, result)
                        )
                    }
                }
                return true
            }
            "getFeatureFlagStringProperty" -> {
                runOnBraze {
                    val flagId = args.getString(0)
                    val propKey = args.getString(1)
                    val result = it.getFeatureFlag(flagId)?.getStringProperty(propKey)
                    if (result == null) {
                        callbackContext.sendCordovaSuccessPluginResultAsNull()
                    } else {
                        callbackContext.sendPluginResult(
                                PluginResult(PluginResult.Status.OK, result)
                        )
                    }
                }
                return true
            }
            "getFeatureFlagNumberProperty" -> {
                runOnBraze {
                    val flagId = args.getString(0)
                    val propKey = args.getString(1)
                    val result = it.getFeatureFlag(flagId)?.getNumberProperty(propKey)
                    if (result == null) {
                        callbackContext.sendCordovaSuccessPluginResultAsNull()
                    } else {
                        callbackContext.sendPluginResult(
                                PluginResult(PluginResult.Status.OK, result.toFloat())
                        )
                    }
                }
                return true
            }
            "getFeatureFlagTimestampProperty" -> {
                runOnBraze {
                    val flagId = args.getString(0)
                    val propKey = args.getString(1)
                    val result = it.getFeatureFlag(flagId)?.getTimestampProperty(propKey)
                    if (result == null) {
                        callbackContext.sendCordovaSuccessPluginResultAsNull()
                    } else {
                        callbackContext.sendPluginResult(PluginResult(PluginResult.Status.OK, result.toFloat()))
                    }
                }
                return true
            }
            "getFeatureFlagJSONProperty" -> {
                runOnBraze {
                    val flagId = args.getString(0)
                    val propKey = args.getString(1)
                    val result = it.getFeatureFlag(flagId)?.getJSONProperty(propKey)
                    if (result == null) {
                        callbackContext.sendCordovaSuccessPluginResultAsNull()
                    } else {
                        callbackContext.sendPluginResult(PluginResult(PluginResult.Status.OK, result))
                    }
                }
                return true
            }
            "getFeatureFlagImageProperty" -> {
                runOnBraze {
                    val flagId = args.getString(0)
                    val propKey = args.getString(1)
                    val result = it.getFeatureFlag(flagId)?.getImageProperty(propKey)
                    if (result == null) {
                        callbackContext.sendCordovaSuccessPluginResultAsNull()
                    } else {
                        callbackContext.sendPluginResult(PluginResult(PluginResult.Status.OK, result))
                    }
                }
                return true
            }
            "logFeatureFlagImpression" -> {
                runOnBraze {
                    Braze.getInstance(applicationContext)
                            .logFeatureFlagImpression(args.getString(0))
                }
                return true
            }
            "subscribeToSdkAuthenticationFailures" -> {
                runOnBraze {
                    it.subscribeToSdkAuthenticationFailures { sdkAuthErrorEvent ->
                        val jsonResult =
                                JSONObject().apply {
                                    put("signature", sdkAuthErrorEvent.signature)
                                    put("errorCode", sdkAuthErrorEvent.errorCode)
                                    put("errorReason", sdkAuthErrorEvent.errorReason)
                                    put("userId", sdkAuthErrorEvent.userId)
                                    put(
                                            "requestInitiationTime",
                                            sdkAuthErrorEvent.requestInitiationTime
                                    )
                                }
                        val result = PluginResult(PluginResult.Status.OK, jsonResult)
                        result.keepCallback = true
                        callbackContext.sendPluginResult(result)
                    }
                }
                return true
            }
            GET_NEWS_FEED_METHOD,
            GET_CARD_COUNT_FOR_CATEGORIES_METHOD,
            GET_UNREAD_CARD_COUNT_FOR_CATEGORIES_METHOD ->
                    return handleNewsFeedGetters(action, args, callbackContext)
            GET_CONTENT_CARDS_FROM_SERVER_METHOD, GET_CONTENT_CARDS_FROM_CACHE_METHOD ->
                    return handleContentCardsUpdateGetters(action, callbackContext)
            LOG_CONTENT_CARDS_CLICKED_METHOD,
            LOG_CONTENT_CARDS_DISMISSED_METHOD,
            LOG_CONTENT_CARDS_IMPRESSION_METHOD ->
                    return handleContentCardsLogMethods(action, args, callbackContext)
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
        // Registers the BrazeInAppMessageManager for the current Activity. This Activity will now
        // listen for
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

    override fun onRequestPermissionResult(
            requestCode: Int,
            permissions: Array<String?>?,
            grantResults: IntArray
    ) {
        when (requestCode) {
            LOCATION_REQUEST_CODE ->
                    if (grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                        brazelog(I) { "Fine location permission granted." }
                        Braze.getInstance(applicationContext).requestLocationInitialization()
                    } else {
                        brazelog(I) { "Fine location permission NOT granted." }
                    }
            else -> {}
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

        // Set the log level.
        if (cordovaPreferences.contains(BRAZE_LOG_LEVEL_PREFERENCE)) {
            when (parseNumericPreferenceAsInteger(
                            cordovaPreferences.getString(BRAZE_LOG_LEVEL_PREFERENCE, "4")
                    )
            ) {
                2 -> logLevel = Log.VERBOSE
                3 -> logLevel = Log.DEBUG
                4 -> logLevel = Log.INFO
                5 -> logLevel = Log.WARN
                6 -> logLevel = Log.ERROR
                7 -> logLevel = Log.ASSERT
                else -> {
                    brazelog(W) { "Invalid log level. Using default value: Log.INFO(4)." }
                }
            }
            brazelog(I) { "Log level set to: $logLevel" }
        }

        // Disable auto starting sessions.
        if (cordovaPreferences.getBoolean(DISABLE_AUTO_START_SESSIONS_PREFERENCE, false)) {
            brazelog { "Disabling session auto starts" }
            disableAutoStartSessions = true
        }

        // Set the values used in the config builder.
        val configBuilder = BrazeConfig.Builder()

        // Set the SDK flavor.
        configBuilder
                .setSdkFlavor(SdkFlavor.CORDOVA)
                .setSdkMetadata(EnumSet.of(BrazeSdkMetadata.CORDOVA))

        // Set the API key.
        if (cordovaPreferences.contains(BRAZE_API_KEY_PREFERENCE) || cordovaPreferences.contains(
                BRAZE_API_KEY_DEPRECATED_PREFERENCE)) {
            var apiKey = cordovaPreferences.getString(BRAZE_API_KEY_PREFERENCE, "")
            if (apiKey.isBlank()) {
                // Fallback to the deprecated API key setting.
                apiKey = cordovaPreferences.getString(BRAZE_API_KEY_DEPRECATED_PREFERENCE, "")
            }
            if (apiKey.isNotBlank()) {
                configBuilder.setApiKey(apiKey)
            } else {
                brazelog(W) { "Invalid Braze API key. API key field not set." }
            }
        }

        // Sets if Braze should automatically opt-in the user when push is authorized by Android.
        if (cordovaPreferences.contains(OPT_IN_WHEN_PUSH_AUTHORIZED_PREFERENCE)) {
            configBuilder.setOptInWhenPushAuthorized(
                    cordovaPreferences.getBoolean(OPT_IN_WHEN_PUSH_AUTHORIZED_PREFERENCE, true)
            )
        }

        // Set the small icon used in notifications using the name of the notification drawable.
        if (cordovaPreferences.contains(SMALL_NOTIFICATION_ICON_PREFERENCE)) {
            val smallNotificationIconName =
                    cordovaPreferences.getString(SMALL_NOTIFICATION_ICON_PREFERENCE, "")
            if (smallNotificationIconName.isNotBlank()) {
                configBuilder.setSmallNotificationIcon(smallNotificationIconName)
            } else {
                brazelog(W) { "Invalid small icon name. Using the app icon as the small icon." }
            }
        }

        // Set the large icon used in notifications using the name of the notification drawable.
        if (cordovaPreferences.contains(LARGE_NOTIFICATION_ICON_PREFERENCE)) {
            val largeNotificationIconName =
                    cordovaPreferences.getString(LARGE_NOTIFICATION_ICON_PREFERENCE, "")
            if (largeNotificationIconName.isNotBlank()) {
                configBuilder.setLargeNotificationIcon(largeNotificationIconName)
            } else {
                brazelog(W) { "Invalid large icon name. Large icon not set." }
            }
        }

        // Set the default accent color for push notifications on Android Lollipop and higher using
        // the hexadecimal color value.
        if (cordovaPreferences.contains(DEFAULT_NOTIFICATION_ACCENT_COLOR_PREFERENCE)) {
            try {
                configBuilder.setDefaultNotificationAccentColor(
                        parseNumericPreferenceAsHexadecimalInteger(
                                cordovaPreferences.getString(
                                        DEFAULT_NOTIFICATION_ACCENT_COLOR_PREFERENCE,
                                        "0"
                                )
                        )
                )
            } catch (e: NumberFormatException) {
                brazelog(W) { "Invalid default notification accent color. Using default value: 0." }
            }
        }

        // Sets the [android.app.NotificationChannel] user facing name as seen via
        // [NotificationChannel.getName] for the Braze default [NotificationChannel].
        if (cordovaPreferences.contains(DEFAULT_NOTIFICATION_CHANNEL_NAME_PREFERENCE)) {
            val notificationChannelName =
                    cordovaPreferences.getString(DEFAULT_NOTIFICATION_CHANNEL_NAME_PREFERENCE, "")
            if (notificationChannelName.isNotBlank()) {
                configBuilder.setDefaultNotificationChannelName(notificationChannelName)
            } else {
                brazelog(W) {
                    "Invalid default notification channel name. Default notification channel name not set."
                }
            }
        }

        // Sets the [android.app.NotificationChannel] user facing description as seen via
        // [NotificationChannel.getDescription] for the Braze default [NotificationChannel].
        if (cordovaPreferences.contains(DEFAULT_NOTIFICATION_CHANNEL_DESCRIPTION_PREFERENCE)) {
            val notificationChannelDescription =
                    cordovaPreferences.getString(
                            DEFAULT_NOTIFICATION_CHANNEL_DESCRIPTION_PREFERENCE,
                            ""
                    )
            if (notificationChannelDescription.isNotBlank()) {
                configBuilder.setDefaultNotificationChannelDescription(
                        notificationChannelDescription
                )
            } else {
                brazelog(W) {
                    "Invalid default notification channel description. Default notification description not set."
                }
            }
        }

        //  Set the length of time before a session times out in seconds.
        if (cordovaPreferences.contains(DEFAULT_SESSION_TIMEOUT_PREFERENCE)) {
            val defaultSessionTimeout =
                    parseNumericPreferenceAsInteger(
                            cordovaPreferences.getString(DEFAULT_SESSION_TIMEOUT_PREFERENCE, "10")
                    )
            if (defaultSessionTimeout >= 0) {
                configBuilder.setSessionTimeout(defaultSessionTimeout)
            } else {
                brazelog(W) { "Invalid default session timeout. Using default value: 10 seconds." }
            }
        }

        // Set whether Braze should automatically open your app and any deep links when a push
        // notification is clicked.
        if (cordovaPreferences.contains(SET_HANDLE_PUSH_DEEP_LINKS_AUTOMATICALLY_PREFERENCE)) {
            configBuilder.setHandlePushDeepLinksAutomatically(
                    cordovaPreferences.getBoolean(
                            SET_HANDLE_PUSH_DEEP_LINKS_AUTOMATICALLY_PREFERENCE,
                            false
                    )
            )
        }

        // Enables Braze to add an activity to the back stack when automatically following deep
        // links for push.
        if (cordovaPreferences.contains(PUSH_DEEP_LINK_BACK_STACK_ACTIVITY_ENABLED_PREFERENCE)) {
            configBuilder.setPushDeepLinkBackStackActivityEnabled(
                    cordovaPreferences.getBoolean(
                            PUSH_DEEP_LINK_BACK_STACK_ACTIVITY_ENABLED_PREFERENCE,
                            true
                    )
            )
        }

        // Sets the activity that Braze will add to the back stack when automatically following deep
        // links for push.
        if (cordovaPreferences.contains(PUSH_DEEP_LINK_BACK_STACK_ACTIVITY_CLASS_NAME_PREFERENCE)) {
            val className =
                    cordovaPreferences.getString(
                            PUSH_DEEP_LINK_BACK_STACK_ACTIVITY_CLASS_NAME_PREFERENCE,
                            ""
                    )
            try {
                val backStackActivityClass: Class<*> = Class.forName(className)
                configBuilder.setPushDeepLinkBackStackActivityClass(backStackActivityClass)
            } catch (e: ClassNotFoundException) {
                brazelog(W) { "Class not found: $className" }
            }
        }

        // Sets the session timeout behavior to be either session-start or session-end based.
        if (cordovaPreferences.contains(SESSION_START_BASED_TIMEOUT_ENABLED_PREFERENCE)) {
            configBuilder.setIsSessionStartBasedTimeoutEnabled(
                    cordovaPreferences.getBoolean(
                            SESSION_START_BASED_TIMEOUT_ENABLED_PREFERENCE,
                            false
                    )
            )
        }

        // Set whether the SDK should automatically register for Firebase Cloud Messaging.
        if (cordovaPreferences.contains(AUTOMATIC_FIREBASE_PUSH_REGISTRATION_ENABLED_PREFERENCE)) {
            configBuilder.setIsFirebaseCloudMessagingRegistrationEnabled(
                    cordovaPreferences.getBoolean(
                            AUTOMATIC_FIREBASE_PUSH_REGISTRATION_ENABLED_PREFERENCE,
                            false
                    )
            )
        }

        // Sets whether a push story is automatically dismissed when clicked.
        if (cordovaPreferences.contains(PUSH_STORY_DISMISS_ON_CLICK_PREFERENCE)) {
            configBuilder.setDoesPushStoryDismissOnClick(
                    cordovaPreferences.getBoolean(PUSH_STORY_DISMISS_ON_CLICK_PREFERENCE, true)
            )
        }

        // Set the sender ID key used to register for Firebase Cloud Messaging.
        if (cordovaPreferences.contains(FCM_SENDER_ID_PREFERENCE)) {
            parseNumericPreferenceAsString(
                            cordovaPreferences.getString(FCM_SENDER_ID_PREFERENCE, "")
                    )
                    ?.let { firebaseSenderId ->
                        configBuilder.setFirebaseCloudMessagingSenderIdKey(firebaseSenderId)
                    }
        }

        // Sets whether the use of a fallback Firebase Cloud Messaging Service is enabled.
        if (cordovaPreferences.contains(FALLBACK_FIREBASE_MESSAGING_SERVICE_ENABLED_PREFERENCE)) {
            configBuilder.setFallbackFirebaseMessagingServiceEnabled(
                    cordovaPreferences.getBoolean(
                            FALLBACK_FIREBASE_MESSAGING_SERVICE_ENABLED_PREFERENCE,
                            true
                    )
            )
        }

        // Sets the classpath for the fallback Firebase Cloud Messaging Service.
        if (cordovaPreferences.contains(FALLBACK_FIREBASE_MESSAGING_SERVICE_CLASSPATH_PREFERENCE)) {
            val fallbackFCMClasspath =
                    cordovaPreferences.getString(
                            FALLBACK_FIREBASE_MESSAGING_SERVICE_CLASSPATH_PREFERENCE,
                            ""
                    )
            if (fallbackFCMClasspath.isNotBlank()) {
                configBuilder.setFallbackFirebaseMessagingServiceClasspath(fallbackFCMClasspath)
            } else {
                brazelog(W) {
                    "Invalid classpath for the fallback Firebase Cloud Messaging Service. Classpath not set."
                }
            }
        }

        // Determines whether the Braze will automatically register tokens in
        // [com.google.firebase.messaging.FirebaseMessagingService.onNewToken].
        if (cordovaPreferences.contains(
                        FIREBASE_MESSAGING_SERVICE_ON_NEW_TOKEN_REGISTRATION_ENABLED_PREFERENCE
                )
        ) {
            configBuilder.setIsFirebaseMessagingServiceOnNewTokenRegistrationEnabled(
                    cordovaPreferences.getBoolean(
                            FIREBASE_MESSAGING_SERVICE_ON_NEW_TOKEN_REGISTRATION_ENABLED_PREFERENCE,
                            true
                    )
            )
        }

        // Sets whether the Content Cards unread visual indication bar is enabled.
        if (cordovaPreferences.contains(CONTENT_CARDS_UNREAD_VISUAL_INDICATOR_ENABLED_PREFERENCE)) {
            configBuilder.setContentCardsUnreadVisualIndicatorEnabled(
                    cordovaPreferences.getBoolean(
                            CONTENT_CARDS_UNREAD_VISUAL_INDICATOR_ENABLED_PREFERENCE,
                            true
                    )
            )
        }

        // Set whether Braze should automatically collect location (if the user permits).
        if (cordovaPreferences.contains(ENABLE_LOCATION_PREFERENCE)) {
            configBuilder.setIsLocationCollectionEnabled(
                    cordovaPreferences.getBoolean(ENABLE_LOCATION_PREFERENCE, false)
            )
        }

        // Set whether the Braze Geofences feature should be enabled.
        if (cordovaPreferences.contains(ENABLE_GEOFENCES_PREFERENCE)) {
            configBuilder.setGeofencesEnabled(
                    cordovaPreferences.getBoolean(ENABLE_GEOFENCES_PREFERENCE, false)
            )
        }

        // Set a custom API endpoint to point to when the Braze singleton is initialized.
        if (cordovaPreferences.contains(CUSTOM_API_ENDPOINT_PREFERENCE)) {
            val customApiEndpoint = cordovaPreferences.getString(CUSTOM_API_ENDPOINT_PREFERENCE, "")
            if (customApiEndpoint.isNotBlank()) {
                configBuilder.setCustomEndpoint(customApiEndpoint)
            } else {
                brazelog(W) {
                    "Invalid custom endpoint. Using the default Braze internal API endpoint."
                }
            }
        }

        // Set whether CordovaInAppMessageViewWrapperFactory should be used to display an In App
        // Message to the user.
        val enableRequestFocusFix =
                cordovaPreferences.getBoolean(
                        ENABLE_CORDOVA_WEBVIEW_REQUEST_FOCUS_FIX_PREFERENCE,
                        true
                )
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P && enableRequestFocusFix) {
            // Addresses Cordova bug in https://issuetracker.google.com/issues/36915710
            BrazeInAppMessageManager.getInstance()
                    .setCustomInAppMessageViewWrapperFactory(
                            CordovaInAppMessageViewWrapperFactory()
                    )
        }

        // Set whether SDK authentication should be enabled.
        if (cordovaPreferences.contains(SDK_AUTH_ENABLED_PREFERENCE)) {
            configBuilder.setIsSdkAuthenticationEnabled(
                    cordovaPreferences.getBoolean(SDK_AUTH_ENABLED_PREFERENCE, false)
            )
        }

        // Set the minimum interval in seconds between trigger actions.
        if (cordovaPreferences.contains(TRIGGER_ACTION_MINIMUM_TIME_INTERVAL_SECONDS_PREFERENCE)) {
            val minimumTimeInterval =
                    parseNumericPreferenceAsInteger(
                            cordovaPreferences.getString(
                                    TRIGGER_ACTION_MINIMUM_TIME_INTERVAL_SECONDS_PREFERENCE,
                                    "30"
                            )
                    )
            if (minimumTimeInterval >= 0) {
                configBuilder.setTriggerActionMinimumTimeIntervalSeconds(minimumTimeInterval)
            } else {
                brazelog(W) {
                    "Invalid minimum time interval between trigger actions. Using default value: 30 seconds."
                }
            }
        }

        // Configure Braze with the configurations in the builder.
        Braze.configure(applicationContext, configBuilder.build())
    }

    private fun handleNewsFeedGetters(
            action: String,
            args: JSONArray,
            callbackContext: CallbackContext
    ): Boolean {
        var feedUpdatedSubscriber: IEventSubscriber<FeedUpdatedEvent>? = null
        var requestingFeedUpdateFromCache = false
        val braze = Braze.getInstance(applicationContext)
        val callbackId = callbackContext.callbackId
        when (action) {
            GET_CARD_COUNT_FOR_CATEGORIES_METHOD -> {
                val categories = getCategoriesFromJSONArray(args)
                feedUpdatedSubscriber = IEventSubscriber { event: FeedUpdatedEvent ->
                    // Each callback context is by default made to only be called once and is
                    // afterwards "finished". We want to ensure
                    // that we never try to call the same callback twice. This could happen since we
                    // don't know the ordering of the feed
                    // subscription callbacks from the cache.
                    if (!callbackContext.isFinished) {
                        callbackContext.success(event.getCardCount(categories))
                    }

                    // Remove this listener from the map
                    braze.removeSingleSubscription(
                            feedSubscriberMap[callbackId],
                            FeedUpdatedEvent::class.java
                    )
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
                    braze.removeSingleSubscription(
                            feedSubscriberMap[callbackId],
                            FeedUpdatedEvent::class.java
                    )
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
                    braze.removeSingleSubscription(
                            feedSubscriberMap[callbackId],
                            FeedUpdatedEvent::class.java
                    )
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

    private fun handleContentCardsUpdateGetters(
            action: String,
            callbackContext: CallbackContext
    ): Boolean {
        // Setup a one-time subscriber for the update event
        val subscriber: IEventSubscriber<ContentCardsUpdatedEvent> =
                object : IEventSubscriber<ContentCardsUpdatedEvent> {
                    override fun trigger(message: ContentCardsUpdatedEvent) {
                        runOnBraze {
                            it.removeSingleSubscription(this, ContentCardsUpdatedEvent::class.java)
                        }

                        // Map the content cards to JSON and return to the client
                        callbackContext.success(mapContentCards(message.allCards))
                    }
                }

        Braze.getInstance(applicationContext).subscribeToContentCardsUpdates(subscriber)
        Braze.getInstance(applicationContext)
                .requestContentCardsRefresh(
                        fromCache = action == GET_CONTENT_CARDS_FROM_CACHE_METHOD
                )
        return true
    }

    @Suppress("ReturnCount")
    private fun handleContentCardsLogMethods(
            action: String,
            args: JSONArray,
            callbackContext: CallbackContext
    ): Boolean {
        val braze = Braze.getInstance(applicationContext)
        if (args.length() != 1) {
            brazelog {
                "Cannot handle logging method for $action due to improper number of arguments. Args: $args"
            }
            callbackContext.error("Failed for action $action")
            return false
        }
        val cardId: String =
                try {
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

    private fun initializeGeofences() {
        val fineLocationPermission = "android.permission.ACCESS_FINE_LOCATION"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val accessBackgroundPermission = "android.permission.ACCESS_BACKGROUND_LOCATION"
            // Get location permissions, if we need them
            if (cordova.hasPermission(fineLocationPermission) &&
                cordova.hasPermission(accessBackgroundPermission)
            ) {
                Braze.getInstance(applicationContext).requestLocationInitialization()
            } else {
                // Request the permission
                cordova.requestPermissions(
                    this,
                    LOCATION_REQUEST_CODE,
                    arrayOf(fineLocationPermission, accessBackgroundPermission)
                )
            }
        } else {
            // Get location permissions, if we need them
            if (cordova.hasPermission(fineLocationPermission)) {
                Braze.getInstance(applicationContext).requestLocationInitialization()
            } else {
                // Request the permission
                cordova.requestPermission(this, LOCATION_REQUEST_CODE, fineLocationPermission)
            }
        }
    }

    private fun setDefaultInAppMessageListener() {
        BrazeInAppMessageManager.getInstance()
            .setCustomInAppMessageManagerListener(
                object : DefaultInAppMessageManagerListener() {
                    override fun beforeInAppMessageDisplayed(
                        inAppMessage: IInAppMessage
                    ): InAppMessageOperation {
                        super.beforeInAppMessageDisplayed(inAppMessage)

                        // Convert in-app message to string
                        val inAppMessageString = inAppMessage.forJsonPut().toString()
                        brazelog { "In-app message received: $inAppMessageString" }

                        // Send in-app message string back to JavaScript in an
                        // `inAppMessageReceived` event
                        val jsStatement = "app.inAppMessageReceived('$inAppMessageString');"
                        cordova.activity.runOnUiThread {
                            webView.engine.evaluateJavascript(jsStatement, null)
                        }

                        return inAppMessageDisplayOperation
                    }
                }
            )
    }

    companion object {
        // Preference keys found in the config.xml
        private const val BRAZE_API_KEY_PREFERENCE = "com.braze.android_api_key"
        private const val BRAZE_API_KEY_DEPRECATED_PREFERENCE = "com.braze.api_key"
        private const val AUTOMATIC_FIREBASE_PUSH_REGISTRATION_ENABLED_PREFERENCE = "com.braze.firebase_cloud_messaging_registration_enabled"
        private const val FCM_SENDER_ID_PREFERENCE = "com.braze.android_fcm_sender_id"
        private const val BRAZE_LOG_LEVEL_PREFERENCE = "com.braze.android_log_level"
        private const val SMALL_NOTIFICATION_ICON_PREFERENCE =
                "com.braze.android_small_notification_icon"
        private const val LARGE_NOTIFICATION_ICON_PREFERENCE =
                "com.braze.android_large_notification_icon"
        private const val DEFAULT_NOTIFICATION_ACCENT_COLOR_PREFERENCE =
                "com.braze.android_notification_accent_color"
        private const val DEFAULT_SESSION_TIMEOUT_PREFERENCE =
                "com.braze.android_default_session_timeout"
        private const val SET_HANDLE_PUSH_DEEP_LINKS_AUTOMATICALLY_PREFERENCE =
                "com.braze.android_handle_push_deep_links_automatically"
        private const val CUSTOM_API_ENDPOINT_PREFERENCE = "com.braze.android_api_endpoint"
        private const val ENABLE_LOCATION_PREFERENCE = "com.braze.enable_location_collection"
        private const val ENABLE_GEOFENCES_PREFERENCE = "com.braze.geofences_enabled"
        private const val DISABLE_AUTO_START_SESSIONS_PREFERENCE =
                "com.braze.android_disable_auto_session_tracking"
        private const val SDK_AUTH_ENABLED_PREFERENCE = "com.braze.sdk_authentication_enabled"
        private const val TRIGGER_ACTION_MINIMUM_TIME_INTERVAL_SECONDS_PREFERENCE =
                "com.braze.trigger_action_minimum_time_interval_seconds"
        private const val SESSION_START_BASED_TIMEOUT_ENABLED_PREFERENCE =
                "com.braze.is_session_start_based_timeout_enabled"
        private const val DEFAULT_NOTIFICATION_CHANNEL_NAME_PREFERENCE =
                "com.braze.default_notification_channel_name"
        private const val DEFAULT_NOTIFICATION_CHANNEL_DESCRIPTION_PREFERENCE =
                "com.braze.default_notification_channel_description"
        private const val PUSH_STORY_DISMISS_ON_CLICK_PREFERENCE =
                "com.braze.does_push_story_dismiss_on_click"
        private const val FALLBACK_FIREBASE_MESSAGING_SERVICE_ENABLED_PREFERENCE =
                "com.braze.is_fallback_firebase_messaging_service_enabled"
        private const val FALLBACK_FIREBASE_MESSAGING_SERVICE_CLASSPATH_PREFERENCE =
                "com.braze.fallback_firebase_messaging_service_classpath"
        private const val CONTENT_CARDS_UNREAD_VISUAL_INDICATOR_ENABLED_PREFERENCE =
                "com.braze.is_content_cards_unread_visual_indicator_enabled"
        private const val FIREBASE_MESSAGING_SERVICE_ON_NEW_TOKEN_REGISTRATION_ENABLED_PREFERENCE =
                "com.braze.is_firebase_messaging_service_on_new_token_registration_enabled"
        private const val PUSH_DEEP_LINK_BACK_STACK_ACTIVITY_ENABLED_PREFERENCE =
                "com.braze.is_push_deep_link_back_stack_activity_enabled"
        private const val PUSH_DEEP_LINK_BACK_STACK_ACTIVITY_CLASS_NAME_PREFERENCE =
                "com.braze.push_deep_link_back_stack_activity_class_name"
        private const val OPT_IN_WHEN_PUSH_AUTHORIZED_PREFERENCE =
                "com.braze.should_opt_in_when_push_authorized"

        /**
         * When applied, restricts the SDK from taking focus away from the Cordova WebView on
         * affected API versions.
         */
        private const val ENABLE_CORDOVA_WEBVIEW_REQUEST_FOCUS_FIX_PREFERENCE =
                "com.braze.android_apply_cordova_webview_focus_request_fix"

        // Numeric preference prefix
        private const val NUMERIC_PREFERENCE_PREFIX = "str_"

        // News Feed method names
        private const val GET_NEWS_FEED_METHOD = "getNewsFeed"
        private const val GET_CARD_COUNT_FOR_CATEGORIES_METHOD = "getCardCountForCategories"
        private const val GET_UNREAD_CARD_COUNT_FOR_CATEGORIES_METHOD =
                "getUnreadCardCountForCategories"

        // Content Card method names
        private const val GET_CONTENT_CARDS_FROM_SERVER_METHOD = "getContentCardsFromServer"
        private const val GET_CONTENT_CARDS_FROM_CACHE_METHOD = "getContentCardsFromCache"
        private const val LOG_CONTENT_CARDS_CLICKED_METHOD = "logContentCardClicked"
        private const val LOG_CONTENT_CARDS_IMPRESSION_METHOD = "logContentCardImpression"
        private const val LOG_CONTENT_CARDS_DISMISSED_METHOD = "logContentCardDismissed"

        // Geofences
        private const val LOCATION_REQUEST_CODE = 271

        private fun getCategoriesFromJSONArray(jsonArray: JSONArray): EnumSet<CardCategory> {
            val categories = EnumSet.noneOf(CardCategory::class.java)
            for (i in 0 until jsonArray.length()) {
                val category = jsonArray.getString(i)
                val categoryArgument: CardCategory? =
                        if (category == "all") {
                            // "All categories" maps to a enumset and not a specific enum so we have
                            // to return that here
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

        /**
         * Map a Kotlin string to a JavaScript-representable version.
         * Escape characters are lost in translation, so we need to manually insert them back in.
         */
        fun escapeStringForJavaScript(input: String): String {
            return input
                .replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\'", "\\\'")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t")
        }

        /**
         * This takes the JSONArray of Any and returns an Array<String?>.
         *
         * Each value in the JSONArray is converted to a String if it has a string representation,
         * otherwise it is set to null.
         */
        private fun parseJSONArrayToStringArray(jsonArray: JSONArray): Array<String?> {
            return Array(jsonArray.length()) { index -> jsonArray.optString(index) }
        }

        /**
         * This takes the JSONArray of Any and creates a JSONArray of explicitly typed JSONObject.
         */
        private fun parseJSONArraytoJsonObjectArray(jsonArray: JSONArray): JSONArray {
            return JSONArray().apply {
                for (i in 0 until jsonArray.length()) {
                    try {
                        this.put(jsonArray.getJSONObject(i))
                    } catch (e: JSONException) {
                        brazelog(W) { "Error parsing JSON at index $i: ${e.message}" }
                    }
                }
            }
        }

        /**
         * This takes the JSONArray of Any type and returns a Double? array
         *
         * A value is converted to Double when it is a non-null number, otherwise it is set to null
         */
        private fun parseJSONArraytoDoubleArray(jsonArray: JSONArray): Array<Double?> {
            return Array(jsonArray.length()) { index ->
                jsonArray.opt(index)?.let { value ->
                    if (isAnyNumeric(value)) value.toString().toDouble() else null
                }
            }
        }

        /** This takes an Any value and returns whether or not it is numeric */
        private fun isAnyNumeric(value: Any): Boolean {
            return when (value) {
                is Int, is Long, is Double -> true
                is String ->
                        value.toDoubleOrNull() != null ||
                                value.toLongOrNull() != null ||
                                value.toIntOrNull() != null
                else -> false
            }
        }

        /**
         * Parses the preference that is optionally prefixed with a constant. Converts the String to
         * String without the prefix, otherwise returns original String.
         *
         * I.e. {"PREFIX-value", "value"} -> {"value"}
         */
        private fun parseNumericPreferenceAsString(preference: String?): String? {
            return preference?.removePrefix(NUMERIC_PREFERENCE_PREFIX)?.also {
                brazelog { "Parsed numeric preference $preference into value: $it" }
            }
        }

        /**
         * Parses the preference that is optionally prefixed with a constant. Converts the String to
         * Int if it is a valid number, otherwise returns -1.
         *
         * I.e. {"PREFIX-value", "value"} -> {"value"}
         */
        private fun parseNumericPreferenceAsInteger(preference: String?): Int {
            val preferenceValue =
                    preference?.removePrefix(NUMERIC_PREFERENCE_PREFIX)?.also {
                        brazelog { "Parsed numeric preference $preference into value: $it" }
                    }
            // Parse the String as an Integer.
            return try {
                preferenceValue?.toInt() ?: -1
            } catch (e: NumberFormatException) {
                -1
            }
        }

        /**
         * Parses the preference that is a hexadecimal representation. Converts the String to Int if
         * it is a valid hexadecimal, otherwise throws NumberFormatException.
         *
         * I.e. {"0x0000"} -> {0}
         */
        private fun parseNumericPreferenceAsHexadecimalInteger(preference: String): Int {
            val preferenceValue =
                    preference.removePrefix("0x").also {
                        brazelog { "Parsed numeric preference $preference into value: $it" }
                    }
            // Parse the String as an Integer.
            return preferenceValue.toInt(16)
        }

        private fun CallbackContext.sendCordovaSuccessPluginResultAsNull() {
            this.sendPluginResult(PluginResult(PluginResult.Status.OK, null as String?))
        }
    }
}
