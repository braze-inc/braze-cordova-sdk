package com.appboy.cordova;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

import com.appboy.Constants;
import com.braze.support.BrazeLogger;

import org.json.JSONException;
import org.json.JSONObject;

public class QAppboyReceiver extends BroadcastReceiver {
  private static final String TAG = BrazeLogger.getBrazeLogTag(QAppboyReceiver.class);
  private static final String DEEPLINK = "deeplink";

  @Override
  public void onReceive(Context context, Intent intent) {
    String action = intent.getAction();
    if (action == null) {
      return;
    }

    Log.d(TAG, String.format("Received intent with action %s", action));

    switch (action) {
     
      case Constants.BRAZE_PUSH_INTENT_NOTIFICATION_OPENED:
        JSONObject json = null;
        String deepLink = intent.getStringExtra(Constants.APPBOY_PUSH_DEEP_LINK_KEY);
        try {
          
          json = new JSONObject().put(DEEPLINK, deepLink);
        } catch (JSONException e) {
          e.printStackTrace();
        }
        if (json != null) {
          AppboyPlugin.sendEvent(json);
        }

        break;
    
      default:
        Log.d(TAG, String.format("Ignoring intent with unsupported action %s", action));
    }
  }
}