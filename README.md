<img src="https://github.com/Appboy/appboy-cordova-sdk/blob/master/braze-logo.png" width="300" title="Braze Logo" />

# Cordova SDK

Effective marketing automation is an essential part of successfully scaling and managing your business. Braze empowers you to build better customer relationships through a seamless, multi-channel approach that addresses all aspects of the user life cycle. Braze helps you engage your users on an ongoing basis. View the following resources for details and we'll have you up and running in no time!

See our [Technical Documentation for Android](https://www.braze.com/docs/developer_guide/platform_integration_guides/cordova/android_and_fireos/initial_sdk_setup/) and [Technical Documentation for iOS](https://www.braze.com/docs/developer_guide/platform_integration_guides/cordova/ios/initial_sdk_setup/) for instructions on integrating Braze into your Cordova app.


## Reason for Fork

The original repo does not allow us to promptForPush at a specific trigger point within the app for iOS. We did not want to ask the user for prompt permission right on app open. 
The repo was forked in order to create a function called promptForPush() for iOS.

A [pull request](https://github.com/Appboy/appboy-cordova-sdk/pull/68) has been submitted to the original repo in case they decide to merge it in, which would allow us to switch back to the original repo and not worry about having to maintain this one.
