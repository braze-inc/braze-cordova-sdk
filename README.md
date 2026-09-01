<img src="https://github.com/braze-inc/braze-cordova-sdk/blob/master/braze-logo.png" width="300" title="Braze Logo" />

# Braze Cordova SDK

Effective marketing automation is an essential part of scaling and managing your business. Braze empowers you to build better customer relationships through a seamless, multichannel approach that addresses all aspects of the user lifecycle. Braze helps you engage your users on an ongoing basis. To get started, see the following resources:

See our instructions for [Integrating the Braze Cordova SDK](https://www.braze.com/docs/developer_guide/platforms/cordova/sdk_integration) into your Cordova app.

## Minimum version requirements

The following table lists the minimum supported versions for the Braze Cordova SDK.

| Braze plugin | Cordova Android | Cordova iOS |
| ------------ | --------------- | ----------- |
| 10.0.0+      | >= 13.0.0       | >= 5.0.0    |
| 2.31.0+      | >= 12.0.0       | >= 5.0.0    |

This SDK also inherits the requirements of its underlying Braze native SDKs. Be sure to also adhere to version support information defined in [braze-inc/braze-android-sdk](https://github.com/braze-inc/braze-android-sdk) and [braze-inc/braze-swift-sdk](https://github.com/braze-inc/braze-swift-sdk).

## Installing the SDK

> [!IMPORTANT]
> Add the Braze Cordova SDK using only the following methods. Using other methods may introduce security risks.

```
# To use the base SDK functionality, install using the `master` branch.

cordova plugin add https://github.com/braze-inc/braze-cordova-sdk#master

# To use location collection and geofences in addition to the base SDK functionality, install using `geofence-branch`.
cordova plugin add https://github.com/braze-inc/braze-cordova-sdk#geofence-branch
```

## Running the sample application
```
cordova plugin remove cordova-plugin-braze
cordova plugin add https://github.com/braze-inc/braze-cordova-sdk#master

# To run android
cordova run android

# To run iOS
cordova run ios
```
