## 2.0.0
- Updates to add functionality for turning off automatic push registration on iOS.  If you want to turn off iOS default push registration, add the preference com.appboy.ios_disable_automatic_push_registration with a value of true.
- Updates to support install parameters to eliminate need for post-install modifications on Android, similar to the support previously offered on the feature/android-variable-integration branch.
- Includes patch for iOS 10 push open bug.  See https://github.com/Appboy/appboy-ios-sdk/releases/tag/2.24.0 for more information.
- Updates Appboy iOS version to 2.24.2.
- Updates Appboy Android version to 1.15+.

## 1.0.0
- Updates plugin to configure Android via parameters (e.g. ported https://github.com/Appboy/appboy-cordova-sdk/tree/feature/android-variable-integration).
- Updates the parameters in https://github.com/Appboy/appboy-cordova-sdk/tree/feature/android-variable-integration to be namespaced for their platform.
- Adds ability to turn off default push registration on iOS.

## 0.1
- Initial release. Adds support for Appboy Android version 1.12+ and Appboy iOS version 2.18.1.
