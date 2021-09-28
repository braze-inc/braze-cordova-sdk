package com.appboy.cordova;

import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.util.Log;

import com.appboy.enums.CardCategory;
import com.appboy.enums.Gender;
import com.appboy.enums.Month;
import com.appboy.enums.NotificationSubscriptionType;
import com.appboy.enums.SdkFlavor;
import com.appboy.events.FeedUpdatedEvent;
import com.appboy.events.IEventSubscriber;
import com.appboy.models.cards.Card;
import com.appboy.models.outgoing.AttributionData;
import com.appboy.ui.activities.AppboyFeedActivity;
import com.braze.Braze;
import com.braze.BrazeUser;
import com.braze.configuration.BrazeConfig;
import com.braze.events.ContentCardsUpdatedEvent;
import com.braze.models.outgoing.BrazeProperties;
import com.braze.support.BrazeLogger;
import com.braze.ui.activities.ContentCardsActivity;
import com.braze.ui.inappmessage.BrazeInAppMessageManager;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaPreferences;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.math.BigDecimal;
import java.util.EnumSet;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class AppboyPlugin extends CordovaPlugin {
  private static final String TAG = "BrazeCordova";

  // Preference keys found in the config.xml
  private static final String APPBOY_API_KEY_PREFERENCE = "com.appboy.api_key";
  private static final String AUTOMATIC_FIREBASE_PUSH_REGISTRATION_ENABLED_PREFERENCE = "com.appboy.firebase_cloud_messaging_registration_enabled";
  private static final String FCM_SENDER_ID_PREFERENCE = "com.appboy.android_fcm_sender_id";
  private static final String APPBOY_LOG_LEVEL_PREFERENCE = "com.appboy.android_log_level";
  private static final String SMALL_NOTIFICATION_ICON_PREFERENCE = "com.appboy.android_small_notification_icon";
  private static final String LARGE_NOTIFICATION_ICON_PREFERENCE = "com.appboy.android_large_notification_icon";
  private static final String DEFAULT_NOTIFICATION_ACCENT_COLOR_PREFERENCE = "com.appboy.android_notification_accent_color";
  private static final String DEFAULT_SESSION_TIMEOUT_PREFERENCE = "com.appboy.android_default_session_timeout";
  private static final String SET_HANDLE_PUSH_DEEP_LINKS_AUTOMATICALLY_PREFERENCE = "com.appboy.android_handle_push_deep_links_automatically";
  private static final String CUSTOM_API_ENDPOINT_PREFERENCE = "com.appboy.android_api_endpoint";
  private static final String ENABLE_LOCATION_PREFERENCE = "com.appboy.enable_location_collection";
  private static final String ENABLE_GEOFENCES_PREFERENCE = "com.appboy.geofences_enabled";
  private static final String DISABLE_AUTO_START_SESSIONS_PREFERENCE = "com.appboy.android_disable_auto_session_tracking";
  /**
   * When applied, restricts the SDK from taking
   * focus away from the Cordova WebView on affected API versions.
   */
  private static final String ENABLE_CORDOVA_WEBVIEW_REQUEST_FOCUS_FIX_PREFERENCE = "com.braze.android_apply_cordova_webview_focus_request_fix";

  // Numeric preference prefix
  private static final String NUMERIC_PREFERENCE_PREFIX = "str_";

  // News Feed method names
  private static final String GET_NEWS_FEED_METHOD = "getNewsFeed";
  private static final String GET_CARD_COUNT_FOR_CATEGORIES_METHOD = "getCardCountForCategories";
  private static final String GET_UNREAD_CARD_COUNT_FOR_CATEGORIES_METHOD = "getUnreadCardCountForCategories";

  // Content Card method names
  private static final String GET_CONTENT_CARDS_FROM_SERVER_METHOD = "getContentCardsFromServer";
  private static final String GET_CONTENT_CARDS_FROM_CACHE_METHOD = "getContentCardsFromCache";
  private static final String LOG_CONTENT_CARDS_DISPLAYED_METHOD = "logContentCardsDisplayed";
  private static final String LOG_CONTENT_CARDS_CLICKED_METHOD = "logContentCardClicked";
  private static final String LOG_CONTENT_CARDS_IMPRESSION_METHOD = "logContentCardImpression";
  private static final String LOG_CONTENT_CARDS_DISMISSED_METHOD = "logContentCardDismissed";

  private boolean mPluginInitializationFinished = false;
  private boolean mDisableAutoStartSessions = false;
  private Context mApplicationContext;
  private final Map<String, IEventSubscriber<FeedUpdatedEvent>> mFeedSubscriberMap = new ConcurrentHashMap<>();

  @Override
  protected void pluginInitialize() {
    mApplicationContext = this.cordova.getActivity().getApplicationContext();

    // Configure Appboy using the preferences from the config.xml file passed to our plugin
    configureFromCordovaPreferences(this.preferences);

    // Since we've likely passed the first Application.onCreate() (due to the plugin lifecycle), lets call the
    // in-app message manager and session handling now
    BrazeInAppMessageManager.getInstance().registerInAppMessageManager(this.cordova.getActivity());
    mPluginInitializationFinished = true;
  }

  @Override
  public boolean execute(final String action, JSONArray args, final CallbackContext callbackContext) throws JSONException {
    initializePluginIfAppropriate();
    Log.i(TAG, "Received " + action + " with the following arguments: " + args);

    switch (action) {
      case "startSessionTracking":
        mDisableAutoStartSessions = false;
        return true;
      case "registerAppboyPushMessages":
        Braze.getInstance(mApplicationContext).registerAppboyPushMessages(args.getString(0));
        return true;
      case "changeUser":
        Braze.getInstance(mApplicationContext).changeUser(args.getString(0));
        return true;
      case "logCustomEvent": {
        BrazeProperties properties = null;
        if (args.get(1) != JSONObject.NULL) {
          properties = new BrazeProperties(args.getJSONObject(1));
        }
        Braze.getInstance(mApplicationContext).logCustomEvent(args.getString(0), properties);
        return true;
      }
      case "logPurchase": {
        String currencyCode = "USD";
        if (args.get(2) != JSONObject.NULL) {
          currencyCode = args.getString(2);
        }
        int quantity = 1;
        if (args.get(3) != JSONObject.NULL) {
          quantity = args.getInt(3);
        }
        BrazeProperties properties = null;
        if (args.get(4) != JSONObject.NULL) {
          properties = new BrazeProperties(args.getJSONObject(4));
        }
        Braze.getInstance(mApplicationContext).logPurchase(args.getString(0), currencyCode, new BigDecimal(args.getDouble(1)), quantity, properties);
        return true;
      }
      case "wipeData":
        Braze.wipeData(mApplicationContext);
        mPluginInitializationFinished = false;
        return true;
      case "enableSdk":
        Braze.enableSdk(mApplicationContext);
        return true;
      case "disableSdk":
        Braze.disableSdk(mApplicationContext);
        mPluginInitializationFinished = false;
        return true;
      case "requestImmediateDataFlush":
        Braze.getInstance(mApplicationContext).requestImmediateDataFlush();
        return true;
      case "requestContentCardsRefresh":
        Braze.getInstance(mApplicationContext).requestContentCardsRefresh(false);
        return true;
      case "getDeviceId":
        callbackContext.success(Braze.getInstance(mApplicationContext).getDeviceId());
        return true;
    }

    // User methods
    BrazeUser currentUser = Braze.getInstance(mApplicationContext).getCurrentUser();
    if (currentUser != null) {
      switch (action) {
        case "setUserAttributionData":
          currentUser.setAttributionData(new AttributionData(args.getString(0), args.getString(1), args.getString(2), args.getString(3)));
          return true;
        case "setStringCustomUserAttribute":
          currentUser.setCustomUserAttribute(args.getString(0), args.getString(1));
          return true;
        case "unsetCustomUserAttribute":
          currentUser.unsetCustomUserAttribute(args.getString(0));
          return true;
        case "setBoolCustomUserAttribute":
          currentUser.setCustomUserAttribute(args.getString(0), args.getBoolean(1));
          return true;
        case "setIntCustomUserAttribute":
          currentUser.setCustomUserAttribute(args.getString(0), args.getInt(1));
          return true;
        case "setDoubleCustomUserAttribute":
          currentUser.setCustomUserAttribute(args.getString(0), (float) args.getDouble(1));
          return true;
        case "setDateCustomUserAttribute":
          currentUser.setCustomUserAttributeToSecondsFromEpoch(args.getString(0), args.getLong(1));
          return true;
        case "incrementCustomUserAttribute":
          currentUser.incrementCustomUserAttribute(args.getString(0), args.getInt(1));
          return true;
        case "setCustomUserAttributeArray":
          String[] attributes = parseJSONArrayToStringArray(args.getJSONArray(1));
          currentUser.setCustomAttributeArray(args.getString(0), attributes);
          return true;
        case "addToCustomAttributeArray":
          currentUser.addToCustomAttributeArray(args.getString(0), args.getString(1));
          return true;
        case "removeFromCustomAttributeArray":
          currentUser.removeFromCustomAttributeArray(args.getString(0), args.getString(1));
          return true;
        case "setFirstName":
          currentUser.setFirstName(args.getString(0));
          return true;
        case "setLastName":
          currentUser.setLastName(args.getString(0));
          return true;
        case "setEmail":
          currentUser.setEmail(args.getString(0));
          return true;
        case "setGender":
          String gender = args.getString(0).toLowerCase();
          switch (gender) {
            case "f":
              currentUser.setGender(Gender.FEMALE);
              break;
            case "m":
              currentUser.setGender(Gender.MALE);
              break;
            case "n":
              currentUser.setGender(Gender.NOT_APPLICABLE);
              break;
            case "o":
              currentUser.setGender(Gender.OTHER);
              break;
            case "p":
              currentUser.setGender(Gender.PREFER_NOT_TO_SAY);
              break;
            case "u":
              currentUser.setGender(Gender.UNKNOWN);
              break;
          }
          return true;
        case "addAlias":
          currentUser.addAlias(args.getString(0), args.getString(1));
          return true;
        case "setDateOfBirth":
          Month month = Month.getMonth(args.getInt(1) - 1);
          currentUser.setDateOfBirth(args.getInt(0), month, args.getInt(2));
          return true;
        case "setCountry":
          currentUser.setCountry(args.getString(0));
          return true;
        case "setHomeCity":
          currentUser.setHomeCity(args.getString(0));
          return true;
        case "setPhoneNumber":
          currentUser.setPhoneNumber(args.getString(0));
          return true;
        case "setAvatarImageUrl":
          currentUser.setAvatarImageUrl(args.getString(0));
          return true;
        case "setPushNotificationSubscriptionType": {
          String subscriptionType = args.getString(0);
          switch (subscriptionType) {
            case "opted_in":
              currentUser.setPushNotificationSubscriptionType(NotificationSubscriptionType.OPTED_IN);
              break;
            case "subscribed":
              currentUser.setPushNotificationSubscriptionType(NotificationSubscriptionType.SUBSCRIBED);
              break;
            case "unsubscribed":
              currentUser.setPushNotificationSubscriptionType(NotificationSubscriptionType.UNSUBSCRIBED);
              break;
          }
          return true;
        }
        case "setEmailNotificationSubscriptionType": {
          String subscriptionType = args.getString(0);
          switch (subscriptionType) {
            case "opted_in":
              currentUser.setEmailNotificationSubscriptionType(NotificationSubscriptionType.OPTED_IN);
              break;
            case "subscribed":
              currentUser.setEmailNotificationSubscriptionType(NotificationSubscriptionType.SUBSCRIBED);
              break;
            case "unsubscribed":
              currentUser.setEmailNotificationSubscriptionType(NotificationSubscriptionType.UNSUBSCRIBED);
              break;
          }
          return true;
        }
        case "setLanguage":
          currentUser.setLanguage(args.getString(0));
          return true;
      }
    }

    // Launching activities
    Intent intent;
    switch (action) {
      case "launchNewsFeed":
        intent = new Intent(mApplicationContext, AppboyFeedActivity.class);
        this.cordova.getActivity().startActivity(intent);
        return true;
      case "launchContentCards":
        intent = new Intent(mApplicationContext, ContentCardsActivity.class);
        this.cordova.getActivity().startActivity(intent);
        return true;
    }

    // News Feed data
    switch (action) {
      case GET_NEWS_FEED_METHOD:
      case GET_CARD_COUNT_FOR_CATEGORIES_METHOD:
      case GET_UNREAD_CARD_COUNT_FOR_CATEGORIES_METHOD:
        return handleNewsFeedGetters(action, args, callbackContext);
    }

    // Content Cards data
    switch (action) {
      case GET_CONTENT_CARDS_FROM_SERVER_METHOD:
      case GET_CONTENT_CARDS_FROM_CACHE_METHOD:
        return handleContentCardsUpdateGetters(action, callbackContext);
      case LOG_CONTENT_CARDS_DISPLAYED_METHOD:
        Braze.getInstance(mApplicationContext).logContentCardsDisplayed();
        return true;
      case LOG_CONTENT_CARDS_CLICKED_METHOD:
      case LOG_CONTENT_CARDS_DISMISSED_METHOD:
      case LOG_CONTENT_CARDS_IMPRESSION_METHOD:
        return handleContentCardsLogMethods(action, args, callbackContext);
    }

    Log.d(TAG, "Failed to execute for action: " + action);
    return false;
  }

  @Override
  public void onPause(boolean multitasking) {
    super.onPause(multitasking);
    initializePluginIfAppropriate();
    BrazeInAppMessageManager.getInstance().unregisterInAppMessageManager(this.cordova.getActivity());
  }

  @Override
  public void onResume(boolean multitasking) {
    super.onResume(multitasking);
    initializePluginIfAppropriate();
    // Registers the BrazeInAppMessageManager for the current Activity. This Activity will now listen for
    // in-app messages from Braze.
    BrazeInAppMessageManager.getInstance().registerInAppMessageManager(this.cordova.getActivity());
  }

  @Override
  public void onStart() {
    super.onStart();
    initializePluginIfAppropriate();
    if (!mDisableAutoStartSessions) {
      Braze.getInstance(mApplicationContext).openSession(this.cordova.getActivity());
    }
  }

  @Override
  public void onStop() {
    super.onStop();
    initializePluginIfAppropriate();
    if (!mDisableAutoStartSessions) {
      Braze.getInstance(mApplicationContext).closeSession(this.cordova.getActivity());
    }
  }

  /**
   * Calls {@link AppboyPlugin#pluginInitialize()} if {@link AppboyPlugin#mPluginInitializationFinished} is false.
   */
  private void initializePluginIfAppropriate() {
    if (!mPluginInitializationFinished) {
      pluginInitialize();
    }
  }

  /**
   * Calls {@link Braze#configure(Context, BrazeConfig)} using the values found from the {@link CordovaPreferences}.
   *
   * @param cordovaPreferences the preferences used to initialize this plugin
   */
  private void configureFromCordovaPreferences(CordovaPreferences cordovaPreferences) {
    BrazeLogger.d(TAG, "Setting Cordova preferences: " + cordovaPreferences.getAll());

    // Set the log level
    if (cordovaPreferences.contains(APPBOY_LOG_LEVEL_PREFERENCE)) {
      BrazeLogger.setLogLevel(cordovaPreferences.getInteger(APPBOY_LOG_LEVEL_PREFERENCE, Log.INFO));
    }

    // Disable auto starting sessions
    if (cordovaPreferences.getBoolean(DISABLE_AUTO_START_SESSIONS_PREFERENCE, false)) {
      BrazeLogger.d(TAG, "Disabling session auto starts");
      mDisableAutoStartSessions = true;
    }

    // Set the values used in the config builder
    BrazeConfig.Builder configBuilder = new BrazeConfig.Builder();

    // Set the flavor
    configBuilder.setSdkFlavor(SdkFlavor.CORDOVA);

    if (cordovaPreferences.contains(APPBOY_API_KEY_PREFERENCE)) {
      configBuilder.setApiKey(cordovaPreferences.getString(APPBOY_API_KEY_PREFERENCE, null));
    }
    if (cordovaPreferences.contains(SMALL_NOTIFICATION_ICON_PREFERENCE)) {
      configBuilder.setSmallNotificationIcon(cordovaPreferences.getString(SMALL_NOTIFICATION_ICON_PREFERENCE, null));
    }
    if (cordovaPreferences.contains(LARGE_NOTIFICATION_ICON_PREFERENCE)) {
      configBuilder.setLargeNotificationIcon(cordovaPreferences.getString(LARGE_NOTIFICATION_ICON_PREFERENCE, null));
    }
    if (cordovaPreferences.contains(DEFAULT_NOTIFICATION_ACCENT_COLOR_PREFERENCE)) {
      configBuilder.setDefaultNotificationAccentColor(parseNumericPreferenceAsInteger(cordovaPreferences.getString(DEFAULT_NOTIFICATION_ACCENT_COLOR_PREFERENCE, "0")));
    }
    if (cordovaPreferences.contains(DEFAULT_SESSION_TIMEOUT_PREFERENCE)) {
      configBuilder.setSessionTimeout(parseNumericPreferenceAsInteger(cordovaPreferences.getString(DEFAULT_SESSION_TIMEOUT_PREFERENCE, "10")));
    }
    if (cordovaPreferences.contains(SET_HANDLE_PUSH_DEEP_LINKS_AUTOMATICALLY_PREFERENCE)) {
      configBuilder.setHandlePushDeepLinksAutomatically(cordovaPreferences.getBoolean(SET_HANDLE_PUSH_DEEP_LINKS_AUTOMATICALLY_PREFERENCE, true));
    }
    if (cordovaPreferences.contains(AUTOMATIC_FIREBASE_PUSH_REGISTRATION_ENABLED_PREFERENCE)) {
      configBuilder.setIsFirebaseCloudMessagingRegistrationEnabled(cordovaPreferences.getBoolean(AUTOMATIC_FIREBASE_PUSH_REGISTRATION_ENABLED_PREFERENCE, true));
    }
    if (cordovaPreferences.contains(FCM_SENDER_ID_PREFERENCE)) {
      configBuilder.setFirebaseCloudMessagingSenderIdKey(parseNumericPreferenceAsString(cordovaPreferences.getString(FCM_SENDER_ID_PREFERENCE, null)));
    }
    if (cordovaPreferences.contains(ENABLE_LOCATION_PREFERENCE)) {
      configBuilder.setIsLocationCollectionEnabled(cordovaPreferences.getBoolean(ENABLE_LOCATION_PREFERENCE, false));
    }
    if (cordovaPreferences.contains(ENABLE_GEOFENCES_PREFERENCE)) {
      configBuilder.setGeofencesEnabled(cordovaPreferences.getBoolean(ENABLE_GEOFENCES_PREFERENCE, false));
    }
    if (cordovaPreferences.contains(CUSTOM_API_ENDPOINT_PREFERENCE)) {
      final String customApiEndpoint = cordovaPreferences.getString(CUSTOM_API_ENDPOINT_PREFERENCE, "");
      if (!customApiEndpoint.equals("")) {
        configBuilder.setCustomEndpoint(customApiEndpoint);
      }
    }

    final boolean enableRequestFocusFix = cordovaPreferences.getBoolean(ENABLE_CORDOVA_WEBVIEW_REQUEST_FOCUS_FIX_PREFERENCE, true);
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P && enableRequestFocusFix) {
      // Addresses Cordova bug in https://issuetracker.google.com/issues/36915710
      BrazeInAppMessageManager.getInstance().setCustomInAppMessageViewWrapperFactory(new CordovaInAppMessageViewWrapper.CordovaInAppMessageViewWrapperFactory());
    }

    Braze.configure(mApplicationContext, configBuilder.build());
  }

  private boolean handleNewsFeedGetters(String action, JSONArray args, final CallbackContext callbackContext) throws JSONException {
    IEventSubscriber<FeedUpdatedEvent> feedUpdatedSubscriber = null;
    boolean requestingFeedUpdateFromCache = false;

    final Braze braze = Braze.getInstance(mApplicationContext);
    final String callbackId = callbackContext.getCallbackId();

    switch (action) {
      case GET_CARD_COUNT_FOR_CATEGORIES_METHOD: {
        final EnumSet<CardCategory> categories = getCategoriesFromJSONArray(args);

        feedUpdatedSubscriber = event -> {
          // Each callback context is by default made to only be called once and is afterwards "finished". We want to ensure
          // that we never try to call the same callback twice. This could happen since we don't know the ordering of the feed
          // subscription callbacks from the cache.
          if (!callbackContext.isFinished()) {
            callbackContext.success(event.getCardCount(categories));
          }

          // Remove this listener from the map and from Appboy
          braze.removeSingleSubscription(mFeedSubscriberMap.get(callbackId), FeedUpdatedEvent.class);
          mFeedSubscriberMap.remove(callbackId);
        };
        requestingFeedUpdateFromCache = true;
        break;
      }
      case GET_UNREAD_CARD_COUNT_FOR_CATEGORIES_METHOD: {
        final EnumSet<CardCategory> categories = getCategoriesFromJSONArray(args);

        feedUpdatedSubscriber = event -> {
          if (!callbackContext.isFinished()) {
            callbackContext.success(event.getUnreadCardCount(categories));
          }

          // Remove this listener from the map and from Appboy
          braze.removeSingleSubscription(mFeedSubscriberMap.get(callbackId), FeedUpdatedEvent.class);
          mFeedSubscriberMap.remove(callbackId);
        };
        requestingFeedUpdateFromCache = true;
        break;
      }
      case GET_NEWS_FEED_METHOD: {
        final EnumSet<CardCategory> categories = getCategoriesFromJSONArray(args);

        feedUpdatedSubscriber = event -> {
          if (!callbackContext.isFinished()) {
            List<Card> cards = event.getFeedCards(categories);
            JSONArray result = new JSONArray();

            for (int i = 0; i < cards.size(); i++) {
              result.put(cards.get(i).forJsonPut());
            }

            callbackContext.success(result);
          }

          // Remove this listener from the map and from Appboy
          braze.removeSingleSubscription(mFeedSubscriberMap.get(callbackId), FeedUpdatedEvent.class);
          mFeedSubscriberMap.remove(callbackId);
        };
        requestingFeedUpdateFromCache = false;
        break;
      }
    }

    if (feedUpdatedSubscriber != null) {
      // Put the subscriber into a map so we can remove it later from future subscriptions
      mFeedSubscriberMap.put(callbackId, feedUpdatedSubscriber);
      braze.subscribeToFeedUpdates(feedUpdatedSubscriber);

      if (requestingFeedUpdateFromCache) {
        braze.requestFeedRefreshFromCache();
      } else {
        braze.requestFeedRefresh();
      }
    }

    return true;
  }

  private boolean handleContentCardsUpdateGetters(String action, final CallbackContext callbackContext) {
    // Setup a one-time subscriber for the update event
    final IEventSubscriber<ContentCardsUpdatedEvent> subscriber = new IEventSubscriber<ContentCardsUpdatedEvent>() {
      @Override
      public void trigger(ContentCardsUpdatedEvent event) {
        Braze.getInstance(mApplicationContext).removeSingleSubscription(this, ContentCardsUpdatedEvent.class);

        // Map the content cards to JSON and return to the client
        callbackContext.success(ContentCardUtils.mapContentCards(event.getAllCards()));
      }
    };
    Braze.getInstance(mApplicationContext).subscribeToContentCardsUpdates(subscriber);
    final boolean updateFromCache = action.equals(GET_CONTENT_CARDS_FROM_CACHE_METHOD);
    Braze.getInstance(mApplicationContext).requestContentCardsRefresh(updateFromCache);
    return true;
  }

  private boolean handleContentCardsLogMethods(String action, JSONArray args, final CallbackContext callbackContext) {
    final Braze braze = Braze.getInstance(mApplicationContext);
    final String cardId;

    if (args.length() != 1) {
      Log.d(TAG, "Cannot handle logging method for " + action + " due to improper number of arguments. Args: " + args);
      callbackContext.error("Failed for action " + action);
      return false;
    }

    try {
      cardId = args.getString(0);
    } catch (JSONException e) {
      Log.e(TAG, "Failed to parse card id from args: " + args, e);
      callbackContext.error("Failed for action " + action);
      return false;
    }

    // Get the list of cards
    // Only obtaining the current list of cached cards is ok since
    // no id passed in could refer to a card on the server that isn't
    // contained in the list of cached cards
    final List<Card> cachedContentCards = braze.getCachedContentCards();

    // Get the desired card by its id
    final Card desiredCard = ContentCardUtils.getCardById(cachedContentCards, cardId);
    if (desiredCard == null) {
      Log.w(TAG, "Couldn't find card in list of cached cards");
      callbackContext.error("Failed for action " + action);
      return false;
    }

    // Perform the appropriate action to the card
    switch (action) {
      case LOG_CONTENT_CARDS_CLICKED_METHOD:
        desiredCard.logClick();
        break;
      case LOG_CONTENT_CARDS_DISMISSED_METHOD:
        desiredCard.setIsDismissed(true);
        break;
      case LOG_CONTENT_CARDS_IMPRESSION_METHOD:
        desiredCard.logImpression();
        break;
    }

    // Return success to the callback
    callbackContext.success();
    return true;
  }

  private static EnumSet<CardCategory> getCategoriesFromJSONArray(JSONArray jsonArray) throws JSONException {
    EnumSet<CardCategory> categories = EnumSet.noneOf(CardCategory.class);

    for (int i = 0; i < jsonArray.length(); i++) {
      String category = jsonArray.getString(i);

      CardCategory categoryArgument;
      if (category.equals("all")) {
        // "All categories" maps to a enumset and not a specific enum so we have to return that here
        return CardCategory.getAllCategories();
      } else {
        categoryArgument = CardCategory.get(category);
      }

      if (categoryArgument != null) {
        categories.add(categoryArgument);
      } else {
        Log.w(TAG, "Tried to add unknown card category: " + category);
      }
    }
    return categories;
  }

  private static String[] parseJSONArrayToStringArray(JSONArray jsonArray) throws JSONException {
    int length = jsonArray.length();
    String[] array = new String[length];
    for (int i = 0; i < length; i++) {
      array[i] = jsonArray.getString(i);
    }
    return array;
  }

  /**
   * Parses the preference that is optionally prefixed with a constant.
   *
   * I.e. {"PREFIX-value", "value"} -> {"value"}
   */
  private static String parseNumericPreferenceAsString(String preference) {
    if (preference != null && preference.startsWith(NUMERIC_PREFERENCE_PREFIX)) {
      String preferenceValue = preference.substring(NUMERIC_PREFERENCE_PREFIX.length(), preference.length());
      BrazeLogger.d(TAG, "Parsed numeric preference " + preference + " into value: " + preferenceValue);
      return preferenceValue;
    }
    return preference;
  }

  /**
   * Parses the preference that is optionally prefixed with a constant.
   *
   * I.e. {"PREFIX-value", "value"} -> {"value"}
   */
  private static int parseNumericPreferenceAsInteger(String preference) {
    String preferenceValue = preference;

    if (preference != null && preference.startsWith(NUMERIC_PREFERENCE_PREFIX)) {
      preferenceValue = preference.substring(NUMERIC_PREFERENCE_PREFIX.length(), preference.length());
      BrazeLogger.d(TAG, "Parsed numeric preference " + preference + " into value: " + preferenceValue);
    }

    // Parse the string as an integer. Note that this is the same decoding used in CordovaPreferences
    return (int)(long)Long.decode(preferenceValue);
  }
}
