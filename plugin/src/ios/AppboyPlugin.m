#import "AppboyPlugin.h"
#import "AppboyKit.h"
#import "ABKAttributionData.h"
#import "AppDelegate+Appboy.h"

@interface AppboyPlugin() <ABKAppboyEndpointDelegate>
  @property NSString *APIKey;
  @property NSString *disableAutomaticPushRegistration;
  @property NSString *disableAutomaticPushHandling;
  @property NSString *apiEndpoint;
@end

@implementation AppboyPlugin

- (NSString *) getApiEndpoint:(NSString *)appboyApiEndpoint {
  return [appboyApiEndpoint stringByReplacingOccurrencesOfString:@"dev.appboy.com" withString:self.apiEndpoint];
}

- (void)pluginInitialize {
  NSDictionary *settings = self.commandDelegate.settings;
  self.APIKey = settings[@"com.appboy.api_key"];
  self.disableAutomaticPushRegistration = settings[@"com.appboy.ios_disable_automatic_push_registration"];
  self.disableAutomaticPushHandling = settings[@"com.appboy.ios_disable_automatic_push_handling"];
  self.apiEndpoint = settings[@"com.appboy.ios_api_endpoint"];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFinishLaunchingListener:) name:UIApplicationDidFinishLaunchingNotification object:nil];
  if (![self.disableAutomaticPushHandling isEqualToString:@"YES"]) {
    [AppDelegate swizzleHostAppDelegate];
  }
}

- (void)didFinishLaunchingListener:(NSNotification *)notification {
  NSMutableDictionary *appboyLaunchOptions = [@{ABKSDKFlavorKey : @(CORDOVA)} mutableCopy];
  
  // Add the endpoint only if it's non nil
  if (self.apiEndpoint != nil) {
    [appboyLaunchOptions setValue:self forKey: ABKAppboyEndpointDelegateKey];
  }

  [Appboy startWithApiKey:self.APIKey
            inApplication:notification.object
        withLaunchOptions:notification.userInfo
        withAppboyOptions:appboyLaunchOptions];

  if (![self.disableAutomaticPushRegistration isEqualToString:@"YES"]) {
    UIUserNotificationType notificationSettingTypes = (UIUserNotificationTypeBadge | UIUserNotificationTypeAlert | UIUserNotificationTypeSound);
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_9_x_Max) {
      UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
      // If the delegate hasn't been set yet, set it here in the plugin
      if (center.delegate == nil) {
        center.delegate = [UIApplication sharedApplication].delegate;
      }
      [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge)
                            completionHandler:^(BOOL granted, NSError * _Nullable error) {
                              NSLog(@"Permission granted.");
      }];
      [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1) {
      UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:notificationSettingTypes categories:nil];
      [[UIApplication sharedApplication] registerForRemoteNotifications];
      [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    } else {
      [[UIApplication sharedApplication] registerForRemoteNotificationTypes: notificationSettingTypes];
    }
  }
}

/*-------Appboy.h-------*/
- (void)changeUser:(CDVInvokedUrlCommand *)command
{
  NSString *userId = [command argumentAtIndex:0 withDefault:nil];
  [[Appboy sharedInstance] changeUser:userId];
}

- (void)submitFeedback:(CDVInvokedUrlCommand *)command {
  NSString *email = [command argumentAtIndex:0 withDefault:nil];
  NSString *message = [command argumentAtIndex:1 withDefault:nil];
  BOOL isReportingABug = [[command argumentAtIndex:2 withDefault:nil] boolValue];
  [[Appboy sharedInstance] submitFeedback:email message:message isReportingABug:isReportingABug];
}

- (void)logCustomEvent:(CDVInvokedUrlCommand *)command {
  NSString *customEventName = [command argumentAtIndex:0 withDefault:nil];
  NSDictionary *properties = [command argumentAtIndex:1 withDefault:nil];
  [[Appboy sharedInstance] logCustomEvent:customEventName withProperties:properties];
}

- (void)logPurchase:(CDVInvokedUrlCommand *)command {
  NSString *purchaseName = [command argumentAtIndex:0 withDefault:nil];
  NSString *currency = [command argumentAtIndex:2 withDefault:@"USD"];
  NSString *price = [[command argumentAtIndex:1 withDefault:nil] stringValue];
  NSUInteger quantity = [[command argumentAtIndex:3 withDefault:@1] integerValue];
  NSDictionary *properties = [command argumentAtIndex:4 withDefault:nil];
  [[Appboy sharedInstance] logPurchase:purchaseName inCurrency:currency atPrice:[NSDecimalNumber decimalNumberWithString:price] withQuantity:quantity andProperties:properties];
}

/*-------ABKUser.h-------*/
- (void) setFirstName:(CDVInvokedUrlCommand *)command {
  NSString *firstName = [command argumentAtIndex:0 withDefault:nil];
  [Appboy sharedInstance].user.firstName = firstName;
}

- (void) setLastName:(CDVInvokedUrlCommand *)command{
  NSString *lastName = [command argumentAtIndex:0 withDefault:nil];
  [Appboy sharedInstance].user.lastName = lastName;
}

- (void) setEmail:(CDVInvokedUrlCommand *)command{
  NSString *email = [command argumentAtIndex:0 withDefault:nil];
  [Appboy sharedInstance].user.email = email;
}

- (void) setGender:(CDVInvokedUrlCommand *)command{
  NSString *gender = [command argumentAtIndex:0 withDefault:nil];
  if ([gender.lowercaseString isEqualToString:@"m"]) {
    [[Appboy sharedInstance].user setGender:ABKUserGenderMale];
  } else if ([gender.lowercaseString isEqualToString:@"f"]) {
    [[Appboy sharedInstance].user setGender:ABKUserGenderFemale];
  }
}

- (void) setDateOfBirth:(CDVInvokedUrlCommand *)command {
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

- (void) setCountry:(CDVInvokedUrlCommand *)command{
  NSString *country = [command argumentAtIndex:0 withDefault:nil];
  [Appboy sharedInstance].user.country = country;
}

- (void) setHomeCity:(CDVInvokedUrlCommand *)command{
  NSString *homeCity = [command argumentAtIndex:0 withDefault:nil];
  [Appboy sharedInstance].user.homeCity = homeCity;
}

- (void) setPhoneNumber:(CDVInvokedUrlCommand *)command{
  NSString *phone = [command argumentAtIndex:0 withDefault:nil];
  [Appboy sharedInstance].user.phone = phone;
}

- (void) setAvatarImageUrl:(CDVInvokedUrlCommand *)command{
  NSString *avatarImageURL = [command argumentAtIndex:0 withDefault:nil];
  [Appboy sharedInstance].user.avatarImageURL = avatarImageURL;
}

- (void) setPushNotificationSubscriptionType:(CDVInvokedUrlCommand *)command {
  NSString *subscriptionType = [command argumentAtIndex:0 withDefault:nil];
  [[Appboy sharedInstance].user setPushNotificationSubscriptionType:[self getSubscriptionTypeFromString:subscriptionType]];
}

- (void) setEmailNotificationSubscriptionType:(CDVInvokedUrlCommand *)command {
  NSString *subscriptionType = [command argumentAtIndex:0 withDefault:nil];
  [[Appboy sharedInstance].user setEmailNotificationSubscriptionType:[self getSubscriptionTypeFromString:subscriptionType]];
}

- (void) setUserAttributionData:(CDVInvokedUrlCommand *)command {
  ABKAttributionData *attributionData = [[ABKAttributionData alloc]
                                         initWithNetwork:[command argumentAtIndex:0 withDefault:nil]
                                         campaign:[command argumentAtIndex:1 withDefault:nil]
                                         adGroup:[command argumentAtIndex:2 withDefault:nil]
                                         creative:[command argumentAtIndex:3 withDefault:nil]];
  [[Appboy sharedInstance].user setAttributionData:attributionData];
}

- (ABKNotificationSubscriptionType) getSubscriptionTypeFromString:(NSString  *)typeString {
  if ([typeString.lowercaseString isEqualToString:@"opted_in"]) {
    return ABKOptedIn;
  } else if ([typeString.lowercaseString isEqualToString:@"unsubscribed"]) {
    return ABKUnsubscribed;
  } else {
    return ABKSubscribed;
  }
}

- (void) setBoolCustomUserAttribute:(CDVInvokedUrlCommand *)command {
  NSString *key = [command argumentAtIndex:0 withDefault:nil];
  NSString *value = [command argumentAtIndex:1 withDefault:nil];
  if (key != nil && value != nil) {
    [[Appboy sharedInstance].user setCustomAttributeWithKey:key andBOOLValue:[value boolValue]];
  }
}

- (void) setStringCustomUserAttribute:(CDVInvokedUrlCommand *)command {
  NSString *key = [command argumentAtIndex:0 withDefault:nil];
  NSString *value = [command argumentAtIndex:1 withDefault:nil];
  if (key != nil && value != nil) {
    [[Appboy sharedInstance].user setCustomAttributeWithKey:key andStringValue:value];
  }
}

- (void) setDoubleCustomUserAttribute:(CDVInvokedUrlCommand *)command {
  NSString *key = [command argumentAtIndex:0 withDefault:nil];
  NSString *value = [command argumentAtIndex:1 withDefault:nil];
  if (key != nil && value != nil) {
    [[Appboy sharedInstance].user setCustomAttributeWithKey:key andDoubleValue:[value doubleValue]];
  }
}

- (void) setDateCustomUserAttribute:(CDVInvokedUrlCommand *)command {
  NSString *key = [command argumentAtIndex:0 withDefault:nil];
  NSString *value = [command argumentAtIndex:1 withDefault:nil];
  if (key != nil && value != nil) {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[value longLongValue]];
    [[Appboy sharedInstance].user setCustomAttributeWithKey:key andDateValue:date];
  }
}

- (void) setIntCustomUserAttribute:(CDVInvokedUrlCommand *)command {
  NSString *key = [command argumentAtIndex:0 withDefault:nil];
  NSString *value = [command argumentAtIndex:1 withDefault:nil];
  if (key != nil && value != nil) {
    [[Appboy sharedInstance].user setCustomAttributeWithKey:key andIntegerValue:[value integerValue]];
  }
}

- (void) setCustomUserAttributeArray:(CDVInvokedUrlCommand *)command {
  NSString *key = [command argumentAtIndex:0 withDefault:nil];
  id value = [command argumentAtIndex:1 withDefault:nil];
  if (key != nil && value != nil && [value isKindOfClass:[NSArray class]]) {
    [[Appboy sharedInstance].user setCustomAttributeArrayWithKey:key array:value];
  }
}

- (void) unsetCustomUserAttribute:(CDVInvokedUrlCommand *)command {
  NSString *key = [command argumentAtIndex:0 withDefault:nil];
  if (key != nil) {
    [[Appboy sharedInstance].user unsetCustomAttributeWithKey:key];
  }
}

- (void) incrementCustomUserAttribute:(CDVInvokedUrlCommand *)command {
  NSString *key = [command argumentAtIndex:0 withDefault:nil];
  NSString *incrementValue = [command argumentAtIndex:1 withDefault:@1];
  if (key != nil) {
    [[Appboy sharedInstance].user incrementCustomUserAttribute:key by:[incrementValue integerValue]];
  }
}

- (void) addToCustomAttributeArray:(CDVInvokedUrlCommand *)command {
  NSString *key = [command argumentAtIndex:0 withDefault:nil];
  NSString *value = [command argumentAtIndex:1 withDefault:nil];
  if (key != nil && value != nil) {
    [[Appboy sharedInstance].user addToCustomAttributeArrayWithKey:key value:value];
  }
}

- (void) removeFromCustomAttributeArray:(CDVInvokedUrlCommand *)command {
  NSString *key = [command argumentAtIndex:0 withDefault:nil];
  NSString *value = [command argumentAtIndex:1 withDefault:nil];
  if (key != nil && value != nil) {
    [[Appboy sharedInstance].user removeFromCustomAttributeArrayWithKey:key value:value];
  }
}

/*-------Appboy UI-------*/
- (void) launchNewsFeed:(CDVInvokedUrlCommand *)command {
  ABKFeedViewControllerModalContext *feedModal = [[ABKFeedViewControllerModalContext alloc] init];
  feedModal.navigationItem.title = @"News";
  [self.viewController presentViewController:feedModal animated:YES completion:nil];
}

- (void) getNewsFeed:(CDVInvokedUrlCommand *)command {
  [[Appboy sharedInstance] requestFeedRefresh];
  int categoryMask = [self getCardCategoryMaskWithStringArray:command.arguments];

  if (categoryMask == 0) {
    [self sendCordovaErrorPluginResultWithString:@"Category could not be set." andCommand:command];
    return;
  }

  NSArray *cards = [[Appboy sharedInstance].feedController getCardsInCategories:categoryMask];
  NSError *e = nil;
  NSMutableArray *result = [NSMutableArray array];

  for (ABKCard *card_item in cards) {
    NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:[card_item serializeToData] options:kNilOptions error: &e];
    [result addObject: jsonArray];
  }

  [self sendCordovaSuccessPluginResultWithArray:result andCommand:command];
}

- (void) launchFeedback:(CDVInvokedUrlCommand *)command {
  ABKFeedbackViewControllerModalContext *feedbackModal = [[ABKFeedbackViewControllerModalContext alloc] init];
  [self.viewController presentViewController:feedbackModal animated:YES completion:nil];
}

/*-------News Feed-------*/
- (void) getCardCountForCategories:(CDVInvokedUrlCommand *)command {
  int categoryMask = [self getCardCategoryMaskWithStringArray:command.arguments];

  if (categoryMask == 0) {
    [self sendCordovaErrorPluginResultWithString:@"Category could not be set." andCommand:command];
    return;
  }

  NSInteger cardCount = [[Appboy sharedInstance].feedController cardCountForCategories:categoryMask];
  [self sendCordovaSuccessPluginResultWithInt:cardCount andCommand:command];
}

- (void) getUnreadCardCountForCategories:(CDVInvokedUrlCommand *)command {
  int categoryMask = [self getCardCategoryMaskWithStringArray:command.arguments];

  if (categoryMask == 0) {
    [self sendCordovaErrorPluginResultWithString:@"Category could not be set." andCommand:command];
    return;
  }

  NSInteger unreadCardCount = [[Appboy sharedInstance].feedController unreadCardCountForCategories:categoryMask];
  [self sendCordovaSuccessPluginResultWithInt:unreadCardCount andCommand:command];
}

- (ABKCardCategory) getCardCategoryMaskWithStringArray:(NSArray *) categories {
  ABKCardCategory categoryMask = 0;
  if (categories != NULL) {
    // Iterate over the categories and get the category mask
    for (NSString *categoryString in categories) {
      if ([categoryString.lowercaseString isEqualToString:@"advertising"]) {
        categoryMask |= ABKCardCategoryAdvertising;
      } else if ([categoryString.lowercaseString isEqualToString:@"announcements"]) {
        categoryMask |= ABKCardCategoryAnnouncements;
      } else if ([categoryString.lowercaseString isEqualToString:@"news"]) {
        categoryMask |= ABKCardCategoryNews;
      } else if ([categoryString.lowercaseString isEqualToString:@"social"]) {
        categoryMask |= ABKCardCategorySocial;
      } else if ([categoryString.lowercaseString isEqualToString:@"no_category"]) {
        categoryMask |= ABKCardCategoryNoCategory;
      } else if ([categoryString.lowercaseString isEqualToString:@"all"]) {
        categoryMask |= ABKCardCategoryAll;
      }
    }
  }
  return categoryMask;
}

- (void) sendCordovaErrorPluginResultWithString:(NSString *)resultMessage andCommand:(CDVInvokedUrlCommand *)command {
  CDVPluginResult *pluginResult = nil;
  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:resultMessage];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) sendCordovaSuccessPluginResultWithInt:(NSUInteger)resultMessage andCommand:(CDVInvokedUrlCommand *)command {
  CDVPluginResult *pluginResult = nil;
  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:resultMessage];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) sendCordovaSuccessPluginResultWithArray:(NSArray *)resultMessage andCommand:(CDVInvokedUrlCommand *)command {
  CDVPluginResult *pluginResult = nil;
  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:resultMessage];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

@end
