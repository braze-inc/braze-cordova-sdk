## 2.20.0

##### Added
- Added the method `getDeviceId()` to the javascript plugin.

## 2.19.0

##### Breaking
- Updated to [Braze iOS SDK 3.29.1](https://github.com/Appboy/appboy-ios-sdk/releases/tag/3.29.1).
- Updated to [Braze Android SDK 11.0.0](https://github.com/Appboy/appboy-android-sdk/releases/tag/v11.0.0).

##### Fixed
- Fixed an issue where the plugin would automatically add the In-app Purchase capability to XCode projects.

##### Added
- Added the methods `addAlias()` and `setLanguage()` to the javascript plugin.

## 2.18.0

##### Breaking
- Updated to [Braze Android SDK 10.0.0](https://github.com/Appboy/appboy-android-sdk/releases/tag/v10.0.0).

## 2.17.0

##### Breaking
- The native iOS bridge uses [Braze iOS SDK 3.27.0](https://github.com/Appboy/appboy-ios-sdk/blob/master/CHANGELOG.md#3270). This release adds support for iOS 14 and requires XCode 12. Please read the Braze iOS SDK changelog for details.

## 2.16.0

##### Changed
- Updated to [Braze Android SDK 8.1.0](https://github.com/Appboy/appboy-android-sdk/releases/tag/v8.1.0).
- Updated to [Braze iOS SDK 3.26.1](https://github.com/Appboy/appboy-ios-sdk/releases/tag/3.26.1).

##### Added
- Added the ability to display notifications while app is in the foreground in iOS. Within `config.xml` set `com.appboy.display_foreground_push_notifications` to `"YES"` to enable this.

## 2.15.0

##### Changed
- Updated to [Braze iOS SDK 3.23.0](https://github.com/Appboy/appboy-ios-sdk/releases/tag/3.23.0).
- Updated to [Braze Android SDK 8.0.1](https://github.com/Appboy/appboy-android-sdk/releases/tag/v8.0.1).

## 2.14.0

##### Changed
- Reverted iOS plugin to use framework tag in `plugin.xml`.
- Updated to [Braze Android SDK 7.0.0](https://github.com/Appboy/appboy-android-sdk/releases/tag/v7.0.0).

## 2.13.0

##### Added
- Added the Content Cards methods `requestContentCardsRefresh(), getContentCardsFromServer(), getContentCardsFromCache(), launchContentCards(), logContentCardsDisplayed(), logContentCardClicked(), logContentCardImpression(), logContentCardDismissed()` to the javascript plugin.
  - `getContentCardsFromServer(), getContentCardsFromCache()` both take a success and error callback to handle return values.

##### Changed
- Updated to [Braze Android SDK 4.0.2](https://github.com/Appboy/appboy-android-sdk/releases/tag/v4.0.2).

## 2.12.0

##### Changed
- Updated to [Braze Android SDK 3.8.0](https://github.com/Appboy/appboy-android-sdk/releases/tag/v3.8.0).
- Pinned Android Gradle plugin version to 3.5.1 in `build-extras.gradle`.
  - Addresses https://github.com/Appboy/appboy-cordova-sdk/issues/46.

## 2.11.2

**Important:** This patch updates the Braze iOS SDK Dependency from 3.20.1 to 3.20.2, which contains important bugfixes. Integrators should upgrade to this patch version. Please see the [Braze iOS SDK Changelog](https://github.com/Appboy/appboy-ios-sdk/blob/master/CHANGELOG.md) for more information.

##### Changed
- Updated to [Braze iOS SDK 3.20.2](https://github.com/Appboy/appboy-ios-sdk/releases/tag/3.20.2).

## 2.11.1

**Important:** This release has known issues displaying HTML in-app messages. Do not upgrade to this version and upgrade to 2.11.2 and above instead. If you are using this version, you are strongly encouraged to upgrade to 2.11.2 or above if you make use of HTML in-app messages.

##### Changed
- Updated to [Braze iOS SDK 3.20.1](https://github.com/Appboy/appboy-ios-sdk/releases/tag/3.20.1).

## 2.11.0

**Important:** This release has known issues displaying HTML in-app messages. Do not upgrade to this version and upgrade to 2.11.2 and above instead. If you are using this version, you are strongly encouraged to upgrade to 2.11.2 or above if you make use of HTML in-app messages.

##### Breaking
- Updated to [Braze iOS SDK 3.20.0](https://github.com/Appboy/appboy-ios-sdk/releases/tag/3.20.0).
- **Important:** Braze iOS SDK 3.20.0 contains updated push token registration methods. We recommend upgrading to this version as soon as possible to ensure a smooth transition as devices upgrade to iOS 13.
- Removes the Feedback feature.
  - `submitFeedback()` and `launchFeedback()` have been removed from the `AppboyPlugin` interface.
- Updated to [Braze Android SDK 3.7.0](https://github.com/Appboy/appboy-android-sdk/releases/tag/v3.7.0).

##### Added
- Added ability to configure location collection in preferences. Braze location collection is now disabled by default.
  - Set `com.appboy.enable_location_collection` to `true/false` on Android.
  - Set `com.appboy.enable_location_collection` to `YES/NO` on iOS.
- Added ability to configure geofences in preferences. Note that the geofences branch is still required to use Braze Geofences out of the box.
  - Set `com.appboy.geofences_enabled` to `true/false` on Android.
  - Set `com.appboy.geofences_enabled` to `YES/NO` on iOS.
  
## 2.10.1

##### Fixed
- Fixed an issue in the iOS plugin where custom endpoints were not correctly getting substituted for the actual server endpoints. 

## 2.10.0

##### Breaking
- Updated to [Braze iOS SDK 3.14.1](https://github.com/Appboy/appboy-ios-sdk/releases/tag/3.14.1).

##### Added
- Added ability for plugin to automatically collect the IDFA information on iOS. To enable, set `com.appboy.ios_enable_idfa_automatic_collection` to `YES` in your `config.xml` project file.
  - ```
    <platform name="ios">
        <preference name="com.appboy.ios_enable_idfa_automatic_collection" value="YES" />
    </platform>
    ```

##### Fixed
- Fixed an issue in the Android plugin where the Braze SDK could be invoked before `pluginInitialize` was called by Cordova. The plugin now explicitly initializes the SDK before any SDK or Android lifecycle methods are called.
  - Fixes https://github.com/Appboy/appboy-cordova-sdk/issues/38

## 2.9.0

##### Breaking
- Updated to [Braze iOS SDK 3.14.0](https://github.com/Appboy/appboy-ios-sdk/releases/tag/3.14.0).
- Updated to [Braze Android SDK 3.2.2](https://github.com/Appboy/appboy-android-sdk/blob/master/CHANGELOG.md#322).

##### Changed
- Changed the iOS plugin to use Cocoapods instead of a framework integration.
- Improved the look and feel of in-app messages to adhere to the latest UX and UI best practices. Changes affect font sizes, padding, and responsiveness across all message types. Now supports button border styling.

##### Fixed
- Fixed the Android plugin not respecting decimal purchase prices.
  - Fixes https://github.com/Appboy/appboy-cordova-sdk/issues/36.

## 2.8.0
- Changed the iOS frameworks to be automatically embedded in the `plugin.xml`.
  - This fixes the "dyld: Library not loaded" issue raised in XCode if the frameworks were not manually embedded.
- Adds method to immediately flush any pending data via `requestImmediateDataFlush()`.

## 2.7.1
- Fixes an issue where sending push on Android resulted in a crash in version 2.7.0. Past versions (before 2.7.0) are unaffected.

## 2.7.0
- Updates Braze Android version to 3.0.0+
  - Removes GCM push registration methods. In your config.xml `com.appboy.android_automatic_push_registration_enabled` and `com.appboy.android_gcm_sender_id` , now have no effect on push registration.
- Updates Braze iOS version to 3.9.0.

## 2.6.0
- Fixes an issue where the Cordova 8.0.0+ build system would convert numeric preferences in the `config.xml` to be floating point numbers.
  - Numeric preferences, such as sender ids, now should be prefixed with `str_` for correct parsing. I.e. `<preference name="com.appboy.android_fcm_sender_id" value="str_64422926741" />`.
- Updates Braze Android version to 2.6.0+

## 2.5.1
- Updates Braze Android version to 2.4.0+.
- Adds Firebase Cloud Messaging automatic registration support. GCM automatic registration should be disabled by setting the config value "com.appboy.android_automatic_push_registration_enabled" to "false". See the Android sample-project's `config.xml` for an example. FCM `config.xml` keys below.
    - "com.appboy.firebase_cloud_messaging_registration_enabled" ("true"/"false")
    - "com.appboy.android_fcm_sender_id" (String)
    - The Firebase dependencies `firebase-messaging` and `firebase-core` are now included automatically as part of the plugin.

## 2.5.0
- Updates Braze Android version to 2.2.5+.
- Updates Braze iOS version to 3.3.4.
- Adds `wipeData()`, `enableSdk()`, and `disableSdk()` methods to the plugin.

## 2.4.0
- Fixes a subdirectory incompatibility issue with Cordova 7.1.0

## 2.3.2
- Adds configuration for custom API endpoints on iOS and Android using the config.xml.
    - Android preference: "com.appboy.android_api_endpoint"
    - iOS preference: "com.appboy.ios_api_endpoint"

## 2.3.1
- Adds getter for all News Feed cards. Thanks to @cwelk for contributing.
- Adds a git branch `geofence-branch` for registering geofences with Google Play Services and messaging on geofence events. Please reach out to success@appboy.com for more information about this feature. The branch has geofences integrated for both Android and iOS.

## 2.3.0
- Fixes in-app messages display issue on iOS.
- Updates Appboy iOS version to 2.29.0
- Updates Appboy Android version to 2.0+
- Fixes original in-app messages not being requested on Android.

## 2.2.0
- Updates Appboy Android version to 1.18+
- Updates Appboy iOS version to 2.25.0
- Adds the ability to configure the Android Cordova SDK using the config.xml. See the Android sample-project's `config.xml` for an example.
    - Supported keys below, see [the AppboyConfig.Builder javadoc](http://appboy.github.io/appboy-android-sdk/javadocs/com/appboy/configuration/AppboyConfig.Builder.html) for more details
    - "com.appboy.api_key" (String)
    - "com.appboy.android_automatic_push_registration_enabled" ("true"/"false")
    - "com.appboy.android_gcm_sender_id" (String)
    - "com.appboy.android_small_notification_icon" (String)
    - "com.appboy.android_large_notification_icon" (String)
    - "com.appboy.android_notification_accent_color" (Integer)
    - "com.appboy.android_default_session_timeout" (String)
    - "com.appboy.android_handle_push_deep_links_automatically" ("true"/"false")
    - "com.appboy.android_log_level" (Integer) can also be configured here, for obtaining debug logs from the Appboy Android SDK
- Updates the Android Cordova SDK to use the [Appboy Lifecycle listener](http://appboy.github.io/appboy-android-sdk/javadocs/com/appboy/AppboyLifecycleCallbackListener.html) to handle session and in-app message registration

## 2.1.0
- Adds support for iOS 10 push registration and handling using the UNUserNotificationCenter.
- Adds functionality for turning off automatic push registration on iOS. To disable, add the preference `com.appboy.ios_disable_automatic_push_handling` with a value of `YES`.

## 2.0.0
- Updates to add functionality for turning off automatic push registration on iOS.  If you want to turn off iOS default push registration, add the preference `com.appboy.ios_disable_automatic_push_registration` with a value of `YES`.
- Includes patch for iOS 10 push open bug.  See https://github.com/Appboy/appboy-ios-sdk/releases/tag/2.24.0 for more information.
- Updates Appboy iOS version to 2.24.2.
- Updates Appboy Android version to 1.15+.
- Updates plugin to configure Android via parameters to eliminate need for post-install modifications on Android. Ported from https://github.com/Appboy/appboy-cordova-sdk/tree/feature/android-variable-integration.

## 0.1
- Initial release. Adds support for Appboy Android version 1.12+ and Appboy iOS version 2.18.1.
