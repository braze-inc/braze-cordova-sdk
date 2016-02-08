#import "AppboyPlugin.h"
#import "AppboyKit.h"

@interface AppboyPlugin()
  @property NSString *APIKey;
@end

@implementation AppboyPlugin
- (void)pluginInitialize
{
  NSDictionary *settings = self.commandDelegate.settings;
  self.APIKey = settings[@"com.appboy.api_key"];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFinishLaunchingListener:) name:UIApplicationDidFinishLaunchingNotification object:nil];
}

- (void)didFinishLaunchingListener:(NSNotification *)notification {
  // TODO - pass api key as paramter
   [Appboy startWithApiKey:self.APIKey
            inApplication:notification.object
        withLaunchOptions:notification.userInfo
        withAppboyOptions:nil];

     // TODO - take param to optionally swith off push registration
   if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1) {
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
     (UIRemoteNotificationTypeAlert |
      UIRemoteNotificationTypeBadge |
      UIRemoteNotificationTypeSound)];
   } else {
     UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeBadge|UIUserNotificationTypeAlert | UIUserNotificationTypeSound) categories:nil];
     [[UIApplication sharedApplication] registerForRemoteNotifications];
     [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    }
}

/*-------Appboy.h-------*/
- (void)changeUser:(CDVInvokedUrlCommand*)command
{
  NSString* userId = [command argumentAtIndex:0 withDefault:nil];
  [[Appboy sharedInstance] changeUser:userId];
}

- (void)submitFeedback:(CDVInvokedUrlCommand*)command {
  NSString* email = [command argumentAtIndex:0 withDefault:nil];
  NSString* message = [command argumentAtIndex:1 withDefault:nil];
  BOOL isReportingABug = [[command argumentAtIndex:2 withDefault:nil] boolValue];
  [[Appboy sharedInstance] submitFeedback:email message:message isReportingABug:isReportingABug];
}

- (void)logCustomEvent:(CDVInvokedUrlCommand*)command {
  NSString* customEventName = [command argumentAtIndex:0 withDefault:nil];
  NSDictionary* properties = [command argumentAtIndex:1 withDefault:nil];
  [[Appboy sharedInstance] logCustomEvent:customEventName withProperties:properties];
}

- (void)logPurchase:(CDVInvokedUrlCommand*)command {
  NSString* purchaseName = [command argumentAtIndex:0 withDefault:nil];
  NSString* currency = [command argumentAtIndex:2 withDefault:@"USD"];
  NSString* price = [[command argumentAtIndex:1 withDefault:nil] stringValue];
  NSUInteger quantity = [[command argumentAtIndex:3 withDefault:@1] integerValue];
  NSDictionary* properties = [command argumentAtIndex:4 withDefault:nil];
  [[Appboy sharedInstance] logPurchase:purchaseName inCurrency:currency atPrice:[NSDecimalNumber decimalNumberWithString:price] withQuantity:quantity andProperties:properties];
}

/*-------ABKUser.h-------*/
- (void) setFirstName:(CDVInvokedUrlCommand*)command {
  NSString* firstName = [command argumentAtIndex:0 withDefault:nil];
  [Appboy sharedInstance].user.firstName = firstName;
}

- (void) setLastName:(CDVInvokedUrlCommand*)command{
  NSString* lastName = [command argumentAtIndex:0 withDefault:nil];
  [Appboy sharedInstance].user.lastName = lastName;
}

- (void) setEmail:(CDVInvokedUrlCommand*)command{
  NSString* email = [command argumentAtIndex:0 withDefault:nil];
  [Appboy sharedInstance].user.email = email;
}

- (void) setGender:(CDVInvokedUrlCommand*)command{
  NSString *gender = [command argumentAtIndex:0 withDefault:nil];
  if ([gender.lowercaseString isEqualToString:@"m"]) {
    [[Appboy sharedInstance].user setGender:ABKUserGenderMale];
  } else if ([gender.lowercaseString isEqualToString:@"f"]) {
    [[Appboy sharedInstance].user setGender:ABKUserGenderFemale];
  }
}

- (void) setDateOfBirth:(CDVInvokedUrlCommand*)command {
  NSInteger year = [[command argumentAtIndex:0 withDefault:@0] integerValue];
  NSInteger month = [[command argumentAtIndex:1 withDefault:@0] integerValue];
  NSInteger day = [[command argumentAtIndex:2 withDefault:@0] integerValue];
  
  if (month <= 12 && month > 0 && day <= 31 && day > 0) {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setDay:day];
    [components setMonth:month];
    [components setYear:year];
    NSDate *date = [calendar dateFromComponents:components];
    [Appboy sharedInstance].user.dateOfBirth = date;
  }
}

- (void) setCountry:(CDVInvokedUrlCommand*)command{
  NSString* country = [command argumentAtIndex:0 withDefault:nil];
  [Appboy sharedInstance].user.country = country;
}

- (void) setHomeCity:(CDVInvokedUrlCommand*)command{
  NSString* homeCity = [command argumentAtIndex:0 withDefault:nil];
  [Appboy sharedInstance].user.homeCity = homeCity;
}

- (void) setPhoneNumber:(CDVInvokedUrlCommand*)command{
  NSString* phone = [command argumentAtIndex:0 withDefault:nil];
  [Appboy sharedInstance].user.phone = phone;
}

- (void) setAvatarImageUrl:(CDVInvokedUrlCommand*)command{
  NSString* avatarImageURL = [command argumentAtIndex:0 withDefault:nil];
  [Appboy sharedInstance].user.avatarImageURL = avatarImageURL;
}

- (void) setPushNotificationSubscriptionType:(CDVInvokedUrlCommand*)command {
  NSString* subscriptionType = [command argumentAtIndex:0 withDefault:nil];
  [[Appboy sharedInstance].user setPushNotificationSubscriptionType:[self getSubscriptionTypeFromString:subscriptionType]];
}

- (void) setEmailNotificationSubscriptionType:(CDVInvokedUrlCommand*)command {
  NSString* subscriptionType = [command argumentAtIndex:0 withDefault:nil];
  [[Appboy sharedInstance].user setEmailNotificationSubscriptionType:[self getSubscriptionTypeFromString:subscriptionType]];
}

- (ABKNotificationSubscriptionType) getSubscriptionTypeFromString:(NSString *)typeString {
  if ([typeString.lowercaseString isEqualToString:@"opted_in"]) {
    return ABKOptedIn;
  } else if ([typeString.lowercaseString isEqualToString:@"unsubscribed"]) {
    return ABKUnsubscribed;
  } else {
    return ABKSubscribed;
  }
}

- (void) setBoolCustomUserAttribute:(CDVInvokedUrlCommand*)command {
  NSString* key = [command argumentAtIndex:0 withDefault:nil];
  NSString* value = [command argumentAtIndex:1 withDefault:nil];
  if (key != nil && value != nil) {
    [[Appboy sharedInstance].user setCustomAttributeWithKey:key andBOOLValue:[value boolValue]];
  }
}

- (void) setStringCustomUserAttribute:(CDVInvokedUrlCommand*)command {
  NSString* key = [command argumentAtIndex:0 withDefault:nil];
  NSString* value = [command argumentAtIndex:1 withDefault:nil];
  if (key != nil && value != nil) {
    [[Appboy sharedInstance].user setCustomAttributeWithKey:key andStringValue:value];
  }
}

- (void) setDoubleCustomUserAttribute:(CDVInvokedUrlCommand*)command {
  NSString* key = [command argumentAtIndex:0 withDefault:nil];
  NSString* value = [command argumentAtIndex:1 withDefault:nil];
  if (key != nil && value != nil) {
    [[Appboy sharedInstance].user setCustomAttributeWithKey:key andDoubleValue:[value doubleValue]];
  }
}

- (void) setDateCustomUserAttribute:(CDVInvokedUrlCommand*)command {
  NSString* key = [command argumentAtIndex:0 withDefault:nil];
  NSString* value = [command argumentAtIndex:1 withDefault:nil];
  if (key != nil && value != nil) {
    NSDate* date = [NSDate dateWithTimeIntervalSince1970:[value longLongValue]];
    [[Appboy sharedInstance].user setCustomAttributeWithKey:key andDateValue:date];
  }
}

- (void) setIntCustomUserAttribute:(CDVInvokedUrlCommand*)command {
  NSString* key = [command argumentAtIndex:0 withDefault:nil];
  NSString* value = [command argumentAtIndex:1 withDefault:nil];
  if (key != nil && value != nil) {
    [[Appboy sharedInstance].user setCustomAttributeWithKey:key andIntegerValue:[value integerValue]];
  }
}

- (void) setCustomUserAttributeArray:(CDVInvokedUrlCommand*)command {
  NSString* key = [command argumentAtIndex:0 withDefault:nil];
  id value = [command argumentAtIndex:1 withDefault:nil];
  if (key != nil && value != nil && [value isKindOfClass:[NSArray class]]) {
    [[Appboy sharedInstance].user setCustomAttributeArrayWithKey:key array:value];
  }
}

- (void) unsetCustomUserAttribute:(CDVInvokedUrlCommand*)command {
  NSString* key = [command argumentAtIndex:0 withDefault:nil];
  if (key != nil) {
    [[Appboy sharedInstance].user unsetCustomAttributeWithKey:key];
  }
}

- (void) incrementCustomUserAttribute:(CDVInvokedUrlCommand*)command {
  NSString* key = [command argumentAtIndex:0 withDefault:nil];
  NSString* incrementValue = [command argumentAtIndex:1 withDefault:@1];
  if (key != nil) {
    [[Appboy sharedInstance].user incrementCustomUserAttribute:key by:[incrementValue integerValue]];
  }
}

- (void) addToCustomAttributeArray:(CDVInvokedUrlCommand*)command {
  NSString* key = [command argumentAtIndex:0 withDefault:nil];
  NSString* value = [command argumentAtIndex:1 withDefault:nil];
  if (key != nil && value != nil) {
    [[Appboy sharedInstance].user addToCustomAttributeArrayWithKey:key value:value];
  }
}

- (void) removeFromCustomAttributeArray:(CDVInvokedUrlCommand*)command {
  NSString* key = [command argumentAtIndex:0 withDefault:nil];
  NSString* value = [command argumentAtIndex:1 withDefault:nil];
  if (key != nil && value != nil) {
    [[Appboy sharedInstance].user removeFromCustomAttributeArrayWithKey:key value:value];
  }
}

/*-------Appboy UI-------*/
- (void)launchNewsFeed:(CDVInvokedUrlCommand*)command {
  ABKFeedViewControllerModalContext *feedModal = [[ABKFeedViewControllerModalContext alloc] init];
  feedModal.navigationItem.title = @"News";
  [self.viewController presentViewController:feedModal animated:YES completion:nil];
}

- (void) launchFeedback:(CDVInvokedUrlCommand*)command {
  ABKFeedbackViewControllerModalContext *feedbackModal = [[ABKFeedbackViewControllerModalContext alloc] init];
  [self.viewController presentViewController:feedbackModal animated:YES completion:nil];
}
@end