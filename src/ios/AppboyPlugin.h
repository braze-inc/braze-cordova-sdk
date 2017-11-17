#import <Cordova/CDV.h>

@interface AppboyPlugin : CDVPlugin <UIAlertViewDelegate> {}

/*-------Appboy.h-------*/
- (void) changeUser:(CDVInvokedUrlCommand *)command;
- (void) submitFeedback:(CDVInvokedUrlCommand *)command;
- (void) logCustomEvent:(CDVInvokedUrlCommand *)command;
- (void) logPurchase:(CDVInvokedUrlCommand *)command;

/*-------ABKUser.h-------*/
- (void) setFirstName:(CDVInvokedUrlCommand *)command;
- (void) setLastName:(CDVInvokedUrlCommand *)command;
- (void) setEmail:(CDVInvokedUrlCommand *)command;
- (void) setGender:(CDVInvokedUrlCommand *)command;
- (void) setDateOfBirth:(CDVInvokedUrlCommand *)command;
- (void) setCountry:(CDVInvokedUrlCommand *)command;
- (void) setHomeCity:(CDVInvokedUrlCommand *)command;
- (void) setPhoneNumber:(CDVInvokedUrlCommand *)command;
- (void) setAvatarImageUrl:(CDVInvokedUrlCommand *)command;

- (void) setPushNotificationSubscriptionType:(CDVInvokedUrlCommand *)command;
- (void) setEmailNotificationSubscriptionType:(CDVInvokedUrlCommand *)command;

- (void) setBoolCustomUserAttribute:(CDVInvokedUrlCommand *)command;
- (void) setStringCustomUserAttribute:(CDVInvokedUrlCommand *)command;
- (void) setDoubleCustomUserAttribute:(CDVInvokedUrlCommand *)command;
- (void) setDateCustomUserAttribute:(CDVInvokedUrlCommand *)command;
- (void) setIntCustomUserAttribute:(CDVInvokedUrlCommand *)command;
- (void) setCustomUserAttributeArray:(CDVInvokedUrlCommand *)command;
- (void) unsetCustomUserAttribute:(CDVInvokedUrlCommand *)command;
- (void) incrementCustomUserAttribute:(CDVInvokedUrlCommand *)command;
- (void) addToCustomAttributeArray:(CDVInvokedUrlCommand *)command;
- (void) removeFromCustomAttributeArray:(CDVInvokedUrlCommand *)command;

/*-------Appboy UI-------*/
- (void) launchNewsFeed:(CDVInvokedUrlCommand *)command;
- (void) launchFeedback:(CDVInvokedUrlCommand *)command;

/*-------News Feed-------*/
- (void) getCardCountForCategories:(CDVInvokedUrlCommand *)command;
- (void) getUnreadCardCountForCategories:(CDVInvokedUrlCommand *)command;
- (void) getNewsFeed:(CDVInvokedUrlCommand *)command;
@end
