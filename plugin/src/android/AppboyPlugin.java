package com.appboy.cordova;

import android.content.Context;
import android.content.Intent;
import android.util.Log;

import com.appboy.Appboy;
import com.appboy.enums.Gender;
import com.appboy.enums.Month;
import com.appboy.enums.NotificationSubscriptionType;
import com.appboy.models.outgoing.AppboyProperties;
import com.appboy.ui.activities.AppboyFeedActivity;
import com.appboy.models.outgoing.AttributionData;
import com.appboy.ui.inappmessage.AppboyInAppMessageManager;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.math.BigDecimal;

public class AppboyPlugin extends CordovaPlugin {
  private static final String TAG = String.format("Appboy.%s", AppboyPlugin.class.getName());
  private boolean mRefreshData;
  private Context mApplicationContext;

  protected void pluginInitialize() {
    mApplicationContext = this.cordova.getActivity().getApplicationContext();
    if (Appboy.getInstance(mApplicationContext).openSession(this.cordova.getActivity())) {
      mRefreshData = true;
    }
    AppboyInAppMessageManager.getInstance().registerInAppMessageManager(this.cordova.getActivity());
    if (mRefreshData) {
      Appboy.getInstance(mApplicationContext).requestInAppMessageRefresh();
      mRefreshData = false;
    }
  }

  public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
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
      Appboy.getInstance(mApplicationContext).getCurrentUser().setAttributionData(new AttributionData(args.getString(0),args.getString(1),args.getString(2),args.getString(3)));
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
    // Other methods
    if (action.equals("launchNewsFeed")) {
      Intent intent = new Intent(mApplicationContext, AppboyFeedActivity.class);
      this.cordova.getActivity().startActivity(intent);
      return true;
    } else if (action.equals("launchFeedback")) {
      Log.i(TAG, "Launch feedback actions are not currently supported on Android. Doing nothing.");
    }

    return false;
  }

  private String[] parseJSONArrayToStringArray(JSONArray jsonArray) throws JSONException {
    int length = jsonArray.length();
    String[] array = new String[length];
    for (int i = 0; i < length; i++){
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
