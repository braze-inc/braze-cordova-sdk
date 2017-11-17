package com.appboy.cordova;

import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.util.Log;

import com.appboy.Appboy;
import com.appboy.IAppboyEndpointProvider;
import com.appboy.configuration.AppboyConfig;
import com.appboy.enums.CardCategory;
import com.appboy.enums.Gender;
import com.appboy.enums.Month;
import com.appboy.enums.NotificationSubscriptionType;
import com.appboy.enums.SdkFlavor;
import com.appboy.events.FeedUpdatedEvent;
import com.appboy.events.IEventSubscriber;
import com.appboy.models.cards.Card;
import com.appboy.models.outgoing.AppboyProperties;
import com.appboy.models.outgoing.AttributionData;
import com.appboy.support.AppboyLogger;
import com.appboy.ui.activities.AppboyFeedActivity;
import com.appboy.ui.inappmessage.AppboyInAppMessageManager;

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
  private static final String TAG = String.format("Appboy.%s", AppboyPlugin.class.getName());

  // Preference keys found in the config.xml
  private static final String APPBOY_API_KEY_PREFERENCE = "com.appboy.api_key";
  private static final String AUTOMATIC_PUSH_REGISTRATION_ENABLED_PREFERENCE = "com.appboy.android_automatic_push_registration_enabled";
  private static final String GCM_SENDER_ID_PREFERENCE = "com.appboy.android_gcm_sender_id";
  private static final String APPBOY_LOG_LEVEL_PREFERENCE = "com.appboy.android_log_level";
  private static final String SMALL_NOTIFICATION_ICON_PREFERENCE = "com.appboy.android_small_notification_icon";
  private static final String LARGE_NOTIFICATION_ICON_PREFERENCE = "com.appboy.android_large_notification_icon";
  private static final String DEFAULT_NOTIFICATION_ACCENT_COLOR_PREFERENCE = "com.appboy.android_notification_accent_color";
  private static final String DEFAULT_SESSION_TIMEOUT_PREFERENCE = "com.appboy.android_default_session_timeout";
  private static final String SET_HANDLE_PUSH_DEEP_LINKS_AUTOMATICALLY_PREFERENCE = "com.appboy.android_handle_push_deep_links_automatically";
  private static final String CUSTOM_API_ENDPOINT_PREFERENCE = "com.appboy.android_api_endpoint";

  // Method names
  private static final String GET_NEWS_FEED_METHOD = "getNewsFeed";
  private static final String GET_CARD_COUNT_FOR_CATEGORIES_METHOD = "getCardCountForCategories";
  private static final String GET_UNREAD_CARD_COUNT_FOR_CATEGORIES_METHOD = "getUnreadCardCountForCategories";
  private Context mApplicationContext;
  private Map<String, IEventSubscriber<FeedUpdatedEvent>> mFeedSubscriberMap = new ConcurrentHashMap<String, IEventSubscriber<FeedUpdatedEvent>>();

  // Original in-app message handling
  private boolean mRefreshData;

  @Override
  protected void pluginInitialize() {
    mApplicationContext = this.cordova.getActivity().getApplicationContext();

    // Configure Appboy using the preferences from the config.xml file passed to our plugin
    configureAppboyFromCordovaPreferences(this.preferences);

    // Since we've likely passed the first Application.onCreate() (due to the plugin lifecycle), lets call the
    // in-app message manager and session handling now
    AppboyInAppMessageManager.getInstance().registerInAppMessageManager(this.cordova.getActivity());

    if (Appboy.getInstance(mApplicationContext).openSession(this.cordova.getActivity())) {
      Appboy.getInstance(mApplicationContext).requestInAppMessageRefresh();
    }
  }

  /**
   * Calls {@link Appboy#configure(Context, AppboyConfig)} using the values found from the {@link CordovaPreferences}.
   *
   * @param cordovaPreferences the preferences used to initialize this plugin
   */
  private void configureAppboyFromCordovaPreferences(CordovaPreferences cordovaPreferences) {
    AppboyLogger.d(TAG, "Setting Cordova preferences: " + cordovaPreferences.getAll());

    // Set the log level
    if (cordovaPreferences.contains(APPBOY_LOG_LEVEL_PREFERENCE)) {
      AppboyLogger.setLogLevel(cordovaPreferences.getInteger(APPBOY_LOG_LEVEL_PREFERENCE, Log.INFO));
    }

    // Set the custom endpoint
    if (cordovaPreferences.contains(CUSTOM_API_ENDPOINT_PREFERENCE)) {
      final String customApiEndpoint = cordovaPreferences.getString(CUSTOM_API_ENDPOINT_PREFERENCE, "");
      if (!customApiEndpoint.equals("")) {
        Appboy.setAppboyEndpointProvider(new IAppboyEndpointProvider() {
          @Override
          public Uri getApiEndpoint(Uri appboyEndpoint) {
            return appboyEndpoint.buildUpon()
                .authority(customApiEndpoint).build();
          }
        });
      }
    }

    // Set the values used in the config builder
    AppboyConfig.Builder configBuilder = new AppboyConfig.Builder();

    // Set the flavor
    configBuilder.setSdkFlavor(SdkFlavor.CORDOVA);

    if (cordovaPreferences.contains(APPBOY_API_KEY_PREFERENCE)) {
      configBuilder.setApiKey(cordovaPreferences.getString(APPBOY_API_KEY_PREFERENCE, null));
    }
    if (cordovaPreferences.contains(AUTOMATIC_PUSH_REGISTRATION_ENABLED_PREFERENCE)) {
      configBuilder.setGcmMessagingRegistrationEnabled(cordovaPreferences.getBoolean(AUTOMATIC_PUSH_REGISTRATION_ENABLED_PREFERENCE, true));
    }
    if (cordovaPreferences.contains(GCM_SENDER_ID_PREFERENCE)) {
      configBuilder.setGcmSenderId(cordovaPreferences.getString(GCM_SENDER_ID_PREFERENCE, null));
    }
    if (cordovaPreferences.contains(SMALL_NOTIFICATION_ICON_PREFERENCE)) {
      configBuilder.setSmallNotificationIcon(cordovaPreferences.getString(SMALL_NOTIFICATION_ICON_PREFERENCE, null));
    }
    if (cordovaPreferences.contains(LARGE_NOTIFICATION_ICON_PREFERENCE)) {
      configBuilder.setLargeNotificationIcon(cordovaPreferences.getString(LARGE_NOTIFICATION_ICON_PREFERENCE, null));
    }
    if (cordovaPreferences.contains(DEFAULT_NOTIFICATION_ACCENT_COLOR_PREFERENCE)) {
      configBuilder.setDefaultNotificationAccentColor(cordovaPreferences.getInteger(DEFAULT_NOTIFICATION_ACCENT_COLOR_PREFERENCE, 0));
    }
    if (cordovaPreferences.contains(DEFAULT_SESSION_TIMEOUT_PREFERENCE)) {
      configBuilder.setSessionTimeout(cordovaPreferences.getInteger(DEFAULT_SESSION_TIMEOUT_PREFERENCE, 10));
    }
    if (cordovaPreferences.contains(SET_HANDLE_PUSH_DEEP_LINKS_AUTOMATICALLY_PREFERENCE)) {
      configBuilder.setHandlePushDeepLinksAutomatically(cordovaPreferences.getBoolean(SET_HANDLE_PUSH_DEEP_LINKS_AUTOMATICALLY_PREFERENCE, true));
    }

    Appboy.configure(mApplicationContext, configBuilder.build());
  }

  @Override
  public boolean execute(String action, JSONArray args, final CallbackContext callbackContext) throws JSONException {
    Log.i(TAG, "Received " + action + " with the following arguments: " + args);
    // Appboy methods
    if (action.equals("registerAppboyPushMessages")) {
      Appboy.getInstance(mApplicationContext).registerAppboyPushMessages(args.getString(0));
      return true;
    } else if (action.equals("changeUser")) {
      Appboy.getInstance(mApplicationContext).changeUser(args.getString(0));
      return true;
    } else if (action.equals("logCustomEvent")) {
      AppboyProperties properties = null;
      if (args.get(1) != JSONObject.NULL) {
        properties = new AppboyProperties(args.getJSONObject(1));
      }
      Appboy.getInstance(mApplicationContext).logCustomEvent(args.getString(0), properties);
      return true;
    } else if (action.equals("logPurchase")) {
      String currencyCode = "USD";
      if (args.get(2) != JSONObject.NULL) {
        currencyCode = args.getString(2);
      }
      int quantity = 1;
      if (args.get(3) != JSONObject.NULL) {
        quantity = args.getInt(3);
      }
      AppboyProperties properties = null;
      if (args.get(4) != JSONObject.NULL) {
        properties = new AppboyProperties(args.getJSONObject(4));
      }
      Appboy.getInstance(mApplicationContext).logPurchase(args.getString(0), currencyCode, new BigDecimal(args.getLong(1)), quantity, properties);
      return true;
    } else if (action.equals("submitFeedback")) {
      Appboy.getInstance(mApplicationContext).submitFeedback(args.getString(0), args.getString(1), args.getBoolean(2));
      return true;
    }
    // Appboy User methods
    if (action.equals("setUserAttributionData")) {
      Appboy.getInstance(mApplicationContext).getCurrentUser().setAttributionData(new AttributionData(args.getString(0), args.getString(1), args.getString(2), args.getString(3)));
      return true;
    } else if (action.equals("setStringCustomUserAttribute")) {
      Appboy.getInstance(mApplicationContext).getCurrentUser().setCustomUserAttribute(args.getString(0), args.getString(1));
      return true;
    } else if (action.equals("unsetCustomUserAttribute")) {
      Appboy.getInstance(mApplicationContext).getCurrentUser().unsetCustomUserAttribute(args.getString(0));
      return true;
    } else if (action.equals("setBoolCustomUserAttribute")) {
      Appboy.getInstance(mApplicationContext).getCurrentUser().setCustomUserAttribute(args.getString(0), args.getBoolean(1));
      return true;
    } else if (action.equals("setIntCustomUserAttribute")) {
      Appboy.getInstance(mApplicationContext).getCurrentUser().setCustomUserAttribute(args.getString(0), args.getInt(1));
      return true;
    } else if (action.equals("setDoubleCustomUserAttribute")) {
      Appboy.getInstance(mApplicationContext).getCurrentUser().setCustomUserAttribute(args.getString(0), (float) args.getDouble(1));
      return true;
    } else if (action.equals("setDateCustomUserAttribute")) {
      Appboy.getInstance(mApplicationContext).getCurrentUser().setCustomUserAttributeToSecondsFromEpoch(args.getString(0), args.getLong(1));
      return true;
    } else if (action.equals("incrementCustomUserAttribute")) {
      Appboy.getInstance(mApplicationContext).getCurrentUser().incrementCustomUserAttribute(args.getString(0), args.getInt(1));
      return true;
    } else if (action.equals("setCustomUserAttributeArray")) {
      String[] attributes = parseJSONArrayToStringArray(args.getJSONArray(1));
      Appboy.getInstance(mApplicationContext).getCurrentUser().setCustomAttributeArray(args.getString(0), attributes);
      return true;
    } else if (action.equals("addToCustomAttributeArray")) {
      Appboy.getInstance(mApplicationContext).getCurrentUser().addToCustomAttributeArray(args.getString(0), args.getString(1));
      return true;
    } else if (action.equals("removeFromCustomAttributeArray")) {
      Appboy.getInstance(mApplicationContext).getCurrentUser().removeFromCustomAttributeArray(args.getString(0), args.getString(1));
      return true;
    } else if (action.equals("setFirstName")) {
      Appboy.getInstance(mApplicationContext).getCurrentUser().setFirstName(args.getString(0));
      return true;
    } else if (action.equals("setLastName")) {
      Appboy.getInstance(mApplicationContext).getCurrentUser().setLastName(args.getString(0));
      return true;
    } else if (action.equals("setEmail")) {
      Appboy.getInstance(mApplicationContext).getCurrentUser().setEmail(args.getString(0));
      return true;
    } else if (action.equals("setGender")) {
      String gender = args.getString(0).toLowerCase();
      if (gender.equals("m")) {
        Appboy.getInstance(mApplicationContext).getCurrentUser().setGender(Gender.MALE);
      } else if (gender.equals("f")) {
        Appboy.getInstance(mApplicationContext).getCurrentUser().setGender(Gender.FEMALE);
      }
      return true;
    } else if (action.equals("setDateOfBirth")) {
      Month month = parseMonth(args.getInt(1));
      Appboy.getInstance(mApplicationContext).getCurrentUser().setDateOfBirth(args.getInt(0), month, args.getInt(2));
      return true;
    } else if (action.equals("setCountry")) {
      Appboy.getInstance(mApplicationContext).getCurrentUser().setCountry(args.getString(0));
      return true;
    } else if (action.equals("setHomeCity")) {
      Appboy.getInstance(mApplicationContext).getCurrentUser().setHomeCity(args.getString(0));
      return true;
    } else if (action.equals("setPhoneNumber")) {
      Appboy.getInstance(mApplicationContext).getCurrentUser().setPhoneNumber(args.getString(0));
      return true;
    } else if (action.equals("setAvatarImageUrl")) {
      Appboy.getInstance(mApplicationContext).getCurrentUser().setAvatarImageUrl(args.getString(0));
      return true;
    } else if (action.equals("setPushNotificationSubscriptionType")) {
      String subscriptionType = args.getString(0);
      if (subscriptionType.equals("opted_in")) {
        Appboy.getInstance(mApplicationContext).getCurrentUser().setPushNotificationSubscriptionType(NotificationSubscriptionType.OPTED_IN);
      } else if (subscriptionType.equals("subscribed")) {
        Appboy.getInstance(mApplicationContext).getCurrentUser().setPushNotificationSubscriptionType(NotificationSubscriptionType.SUBSCRIBED);
      } else if (subscriptionType.equals("unsubscribed")) {
        Appboy.getInstance(mApplicationContext).getCurrentUser().setPushNotificationSubscriptionType(NotificationSubscriptionType.UNSUBSCRIBED);
      }
      return true;
    } else if (action.equals("setEmailNotificationSubscriptionType")) {
      String subscriptionType = args.getString(0);
      if (subscriptionType.equals("opted_in")) {
        Appboy.getInstance(mApplicationContext).getCurrentUser().setEmailNotificationSubscriptionType(NotificationSubscriptionType.OPTED_IN);
      } else if (subscriptionType.equals("subscribed")) {
        Appboy.getInstance(mApplicationContext).getCurrentUser().setEmailNotificationSubscriptionType(NotificationSubscriptionType.SUBSCRIBED);
      } else if (subscriptionType.equals("unsubscribed")) {
        Appboy.getInstance(mApplicationContext).getCurrentUser().setEmailNotificationSubscriptionType(NotificationSubscriptionType.UNSUBSCRIBED);
      }
      return true;
    }

    // Launching activities
    if (action.equals("launchNewsFeed")) {
      Intent intent = new Intent(mApplicationContext, AppboyFeedActivity.class);
      this.cordova.getActivity().startActivity(intent);
      return true;
    } else if (action.equals("launchFeedback")) {
      Log.i(TAG, "Launch feedback actions are not currently supported on Android. Doing nothing.");
    }

    // News Feed data
    if (action.equals(GET_CARD_COUNT_FOR_CATEGORIES_METHOD) || action.equals(GET_UNREAD_CARD_COUNT_FOR_CATEGORIES_METHOD) || action.equals(GET_NEWS_FEED_METHOD)) {
      return handleNewsFeedGetters(action, args, callbackContext);
    }

    return false;
  }

  private boolean handleNewsFeedGetters(String action, JSONArray args, final CallbackContext callbackContext) throws JSONException {
    IEventSubscriber<FeedUpdatedEvent> feedUpdatedSubscriber = null;
    boolean requestingFeedUpdateFromCache = false;

    final Appboy mAppboy = Appboy.getInstance(mApplicationContext);
    final String callbackId = callbackContext.getCallbackId();

    if (action.equals(GET_CARD_COUNT_FOR_CATEGORIES_METHOD)) {
      final EnumSet<CardCategory> categories = getCategoriesFromJSONArray(args);

      feedUpdatedSubscriber = new IEventSubscriber<FeedUpdatedEvent>() {
        @Override
        public void trigger(final FeedUpdatedEvent event) {
          // Each callback context is by default made to only be called once and is afterwards "finished". We want to ensure
          // that we never try to call the same callback twice. This could happen since we don't know the ordering of the feed
          // subscription callbacks from the cache.
          if (!callbackContext.isFinished()) {
            callbackContext.success(event.getCardCount(categories));
          }

          // Remove this listener from the map and from Appboy
          mAppboy.removeSingleSubscription(mFeedSubscriberMap.get(callbackId), FeedUpdatedEvent.class);
          mFeedSubscriberMap.remove(callbackId);
        }
      };
      requestingFeedUpdateFromCache = true;
    } else if (action.equals(GET_UNREAD_CARD_COUNT_FOR_CATEGORIES_METHOD)) {
      final EnumSet<CardCategory> categories = getCategoriesFromJSONArray(args);

      feedUpdatedSubscriber = new IEventSubscriber<FeedUpdatedEvent>() {
        @Override
        public void trigger(final FeedUpdatedEvent event) {
          if (!callbackContext.isFinished()) {
            callbackContext.success(event.getUnreadCardCount(categories));
          }

          // Remove this listener from the map and from Appboy
          mAppboy.removeSingleSubscription(mFeedSubscriberMap.get(callbackId), FeedUpdatedEvent.class);
          mFeedSubscriberMap.remove(callbackId);
        }
      };
      requestingFeedUpdateFromCache = true;
    } else if (action.equals(GET_NEWS_FEED_METHOD)) {
      final EnumSet<CardCategory> categories = getCategoriesFromJSONArray(args);

      feedUpdatedSubscriber = new IEventSubscriber<FeedUpdatedEvent>() {
        @Override
        public void trigger(final FeedUpdatedEvent event) {
          if (!callbackContext.isFinished()) {
            List<Card> cards = event.getFeedCards(categories);
            JSONArray result = new JSONArray();

            for (int i = 0; i < cards.size(); i++) {
              result.put(cards.get(i).forJsonPut());
            }

            callbackContext.success(result);
          }

          // Remove this listener from the map and from Appboy
          mAppboy.removeSingleSubscription(mFeedSubscriberMap.get(callbackId), FeedUpdatedEvent.class);
          mFeedSubscriberMap.remove(callbackId);
        }
      };
      requestingFeedUpdateFromCache = false;
    }

    // Put the subscriber into a map so we can remove it later from future subscriptions
    mFeedSubscriberMap.put(callbackId, feedUpdatedSubscriber);
    mAppboy.subscribeToFeedUpdates(feedUpdatedSubscriber);

    if (requestingFeedUpdateFromCache) {
      mAppboy.requestFeedRefreshFromCache();
    } else {
      mAppboy.requestFeedRefresh();
    }

    return true;
  }

  private EnumSet<CardCategory> getCategoriesFromJSONArray(JSONArray jsonArray) throws JSONException {
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

  private String[] parseJSONArrayToStringArray(JSONArray jsonArray) throws JSONException {
    int length = jsonArray.length();
    String[] array = new String[length];
    for (int i = 0; i < length; i++) {
      array[i] = jsonArray.getString(i);
    }
    return array;
  }

  private Month parseMonth(int monthInt) {
    switch (monthInt) {
      case 1:
        return Month.JANUARY;
      case 2:
        return Month.FEBRUARY;
      case 3:
        return Month.MARCH;
      case 4:
        return Month.APRIL;
      case 5:
        return Month.MAY;
      case 6:
        return Month.JUNE;
      case 7:
        return Month.JULY;
      case 8:
        return Month.AUGUST;
      case 9:
        return Month.SEPTEMBER;
      case 10:
        return Month.OCTOBER;
      case 11:
        return Month.NOVEMBER;
      case 12:
        return Month.DECEMBER;
      default:
        return null;
    }
  }

  @Override
  public void onPause(boolean multitasking) {
    super.onPause(multitasking);
    AppboyInAppMessageManager.getInstance().unregisterInAppMessageManager(this.cordova.getActivity());
  }

  @Override
  public void onResume(boolean multitasking) {
    super.onResume(multitasking);
    // Registers the AppboyInAppMessageManager for the current Activity. This Activity will now listen for
    // in-app messages from Appboy.
    AppboyInAppMessageManager.getInstance().registerInAppMessageManager(this.cordova.getActivity());
    if (mRefreshData) {
      Appboy.getInstance(mApplicationContext).requestInAppMessageRefresh();
      mRefreshData = false;
    }
  }

  @Override
  public void onStart() {
    super.onStart();
    if (Appboy.getInstance(mApplicationContext).openSession(this.cordova.getActivity())) {
      mRefreshData = true;
    }
  }

  @Override
  public void onStop() {
    super.onStop();
    Appboy.getInstance(mApplicationContext).closeSession(this.cordova.getActivity());
  }
}
