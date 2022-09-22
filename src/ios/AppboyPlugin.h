#import <Cordova/CDV.h>

@interface AppboyPlugin : CDVPlugin <UIAlertViewDelegate> {}

/*-------Appboy.h-------*/
- (void) changeUser:(CDVInvokedUrlCommand *)command;
- (void) logCustomEvent:(CDVInvokedUrlCommand *)command;
- (void) logPurchase:(CDVInvokedUrlCommand *)command;
- (void) disableSdk:(CDVInvokedUrlCommand *)command;
- (void) enableSdk:(CDVInvokedUrlCommand *)command;
- (void) wipeData:(CDVInvokedUrlCommand *)command;
- (void) requestImmediateDataFlush:(CDVInvokedUrlCommand *)command;
- (void) getDeviceId:(CDVInvokedUrlCommand *)command;
- (void) hasUserAnsweredNotificationPrompt:(CDVInvokedUrlCommand *)command;
- (void) registerPushNotification:(CDVInvokedUrlCommand *)command;

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
- (void) setLanguage:(CDVInvokedUrlCommand *)command;

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
- (void) addAlias:(CDVInvokedUrlCommand *)command;

/*-------Appboy UI-------*/
- (void) launchNewsFeed:(CDVInvokedUrlCommand *)command;
- (void) launchContentCards:(CDVInvokedUrlCommand *)command;

/*-------News Feed-------*/
- (void) getCardCountForCategories:(CDVInvokedUrlCommand *)command;
- (void) getUnreadCardCountForCategories:(CDVInvokedUrlCommand *)command;
- (void) getNewsFeed:(CDVInvokedUrlCommand *)command;

/*-------Content Cards-------*/
- (void) requestContentCardsRefresh:(CDVInvokedUrlCommand *)command;
- (void) getContentCardsFromServer:(CDVInvokedUrlCommand *)command;
- (void) getContentCardsFromCache:(CDVInvokedUrlCommand *)command;
- (void) logContentCardClicked:(CDVInvokedUrlCommand *)command;
- (void) logContentCardImpression:(CDVInvokedUrlCommand *)command;
- (void) logContentCardDismissed:(CDVInvokedUrlCommand *)command;

@end
