![Appboy Logo](https://github.com/Appboy/appboy-cordova-sdk/blob/master/Appboy_Logo_400x100.png)

# Cordova SDK

Effective marketing automation is an essential part of successfully scaling and managing your business. Appboy empowers you to build better customer relationships through a seamless, multi-channel approach that addresses all aspects of the user life cycle Appboy helps you engage your users on an ongoing basis. View the following resources for details and we'll have you up and running in no time!

## Getting Started

Download the SDK and run `cordova plugin add path_to_repo\plugin\` from the root your project.

### iOS setup

In your app's config.xml, add a `preference` element under the iOS `platform` element that contains your Appboy API key with the name `com.appboy.api_key`:

```
    <platform name="ios">
        <preference name="com.appboy.api_key" value="YOUR_API_KEY" />
        ...
    </platform>
```

Set up your applications to have the appropriate certificates for push, via the directions at https://documentation.appboy.com/iOS/#push-notifications.

__Note:__ By default we instrument registering for push automatically in this SDK, so push is a 0-touch integration.

If you want to turn off iOS default push registration, add the preference `com.appboy.ios_disable_automatic_push_registration` with a value of `YES`.

If you want to turn off iOS default push handling, add the preference `com.appboy.ios_disable_automatic_push_handling` with a value of `YES`.

As of SDK version 2.1.0, use of the iOS SDK requires XCode 8 or above.
### Android Automated Setup

The Android variant of this SDK requires 3 variables to be set when adding the plugin.  

```
$APPBOY_ANDROID_API_KEY // Your Appboy API key.
$APPBOY_ANDROID_PUSH_REGISTRATION_ENABLED // Whether Appboy should register for push (default setup should set true).
$APPBOY_ANDROID_GCM_SENDER_ID // Your GCM sender Id as described here:  https://documentation.appboy.com/Android/#push-notifications
```

Using the standard cordova variable syntax, you can install the SDK so that the above variables are automatically inserted during plugin installation like:

```
cordova plugin add path_to_repo\plugin\ --variable APPBOY_ANDROID_GCM_SENDER_ID=SENDER_ID --variable APPBOY_ANDROID_API_KEY=API_KEY --variable APPBOY_ANDROID_PUSH_REGISTRATION_ENABLED=true\false
```

## Deep Linking (Android)

The following is a deep linking example that allows for the URI `appboy://cordova/feed` to open the Appboy News Feed inside your Cordova app.

```
<platform name="android">
  <config-file target="AndroidManifest.xml" parent="/manifest/application">
      ...
      <activity android:name="com.appboy.ui.activities.AppboyFeedActivity">
        <intent-filter>
          <action android:name="android.intent.action.VIEW" />
          <category android:name="android.intent.category.DEFAULT" />
          <category android:name="android.intent.category.BROWSABLE" />
          <!-- Accepts the URI "appboy://cordova/feed” -->
          <data android:scheme="appboy"
                android:host="cordova"
                android:pathPrefix="/feed" />
        </intent-filter>
      </activity>
      ...
    </config-file>
</platform>
```

## Customized Setup

Note that this plugin can be forked and modified for custom implementations.  Find the platform-specific native source code in the `\plugin\src` directory, the javascript interface in the `\plugin\www` directory, and the main configuration file at `\plugin`.

Users that check their platform directory into version control (enabling them to make permanent code edits there) will be able to further leverage Appboy's UI elements by calling them directly from their platform specific project.

#### Disabling automatic push setup (Android)
To remove automatic push registration on Android, set the `APPBOY_ANDROID_PUSH_REGISTRATION_ENABLED` value to false. If using the automatic setup, `false` can be passed as a variable here. Otherwise, modify the preference in the plugin.xml. 

#### Disabling automatic push registration (iOS)
To remove automatic push registration on iOS, set the preference `com.appboy.ios_disable_automatic_push_registration` to `YES` as outlined in the iOS setup earlier.

#### Disabling automatic push handling (iOS)
To remove automatic push handling on iOS, set the preference `com.appboy.ios_disable_automatic_push_handling` to `YES` in your config.xml file. Push handling disabled results in none of the methods in your AppDelegate being swizzled and is reccommended for when you want to call Appboy SDK methods manually.