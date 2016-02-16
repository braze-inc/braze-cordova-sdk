![Appboy Logo](https://github.com/Appboy/appboy-cordova-sdk/blob/master/Appboy_Logo_400x100.png)

# Cordova SDK

Effective marketing automation is an essential part of successfully scaling and managing your business. Appboy empowers you to build better customer relationships through a seamless, multi-channel approach that addresses all aspects of the user life cycle Appboy helps you engage your users on an ongoing basis. Visit the following link for details and we'll have you up and running in no time!

## Getting Started (Default setup)

Download the SDK and run `cordova plugin add path_to_repo/plugin/` from the root your project.

### iOS

In your config.xml, add a `preference` element under the iOS `platform` element that contains your Appboy API key with the name `com.appboy.api_key`:

```
    <platform name="ios">
        <preference name="com.appboy.api_key" value="YOUR_API_KEY" />
        ...
    </platform>
```

Set up your applications to have the appropriate certificates for push, via the directions at https://documentation.appboy.com/iOS/#push-notifications.

__Note:__ By default we instrument registering for push automatically in this SDK, so push is a 0-touch integration.

### Android

The Android variant of this SDK requires 4 variables (in 2 files) to be set when adding the plugin.  

In `appboy.xml`:

```
$APPBOY_API_KEY // Your Appboy API key.
$APPBOY_PUSH_REGISTRATION_ENABLED // Whether Appboy should register for push (default setup should set true).
$APPBOY_GCM_SENDER_ID // Your GCM sender Id as described here:  https://documentation.appboy.com/Android/#push-notifications
```

In `AppboyBroadcastReceiver.java`:
```
$PACKAGE_NAME // The package name of your Android application/Cordova project.
```

For users that don't save their platform directory in version control, consider setting these from a script as part of your initial setup.  An example exists in the sample-project directory `replace_android_tokens.sh`.

## Customized Setup

Note that this plugin can be forked and modified for custom implementations.  Find the platform-specific native source code in the `/plugin/src` directory, the javascript interface in the `/plugin/www` directory, and the main configuration file at `/plugin`.

Users that check their platform directory into version control (enabling them to make permanent code edits there) will be able to further leverage Appboy's UI elements by calling them directly from their platform specific project.

#### Removing automatic push setup (Android)
To remove automatic push registration on Android, set `com_appboy_push_gcm_messaging_registration_enabled` to `false` and don't include a `com_appboy_push_gcm_sender_id` element in your `appboy.xml`.  To further remove all automatic push setup, remove `AppboyBroadcastRecevier.java` from the plugin and its declaration in `plugin.xml`.

#### Removing automatic push setup (iOS)
To remove automatic push registration on iOS, remove `didFinishLaunchingListener` from `AppboyPlugin.m`.  To further remove all automatic setup, remove `AppDelegate+Appboy.h` and `AppboyDelegate+Appboy.m` from the plugin and their references in `plugin.xml`.