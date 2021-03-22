#import "AppboyPlugin.h"
#if __has_include(<Appboy_iOS_SDK/AppboyKit.h>)
#import <Appboy_iOS_SDK/AppboyKit.h>
#import <Appboy_iOS_SDK/ABKAttributionData.h>
#import <Appboy_iOS_SDK/AppboyNewsFeed.h>
#import <Appboy_iOS_SDK/AppboyContentCards.h>
#elif __has_include(<Appboy-iOS-SDK/Appboy_iOS_SDK.framework/Headers/AppboyKit.h>)
#import <Appboy-iOS-SDK/Appboy_iOS_SDK.framework/Headers/AppboyKit.h>
#import <Appboy-iOS-SDK/Appboy_iOS_SDK.framework/Headers/ABKAttributionData.h>
#import <Appboy-iOS-SDK/Appboy_iOS_SDK.framework/Headers/AppboyNewsFeed.h>
#import <Appboy-iOS-SDK/Appboy_iOS_SDK.framework/Headers/AppboyContentCards.h>
#else
#import "AppboyKit.h"
#import "ABKAttributionData.h"
#import "AppboyNewsFeed.h"
#import "AppboyContentCards.h"
#endif

#import "AppDelegate+Appboy.h"
#import "IDFADelegate.h"

@interface AppboyPlugin()
  @property NSString *APIKey;
  @property NSString *disableAutomaticPushRegistration;
  @property NSString *disableAutomaticPushHandling;
  @property NSString *apiEndpoint;
  @property NSString *enableIDFACollection;
  @property NSString *enableLocationCollection;
  @property NSString *enableGeofences;
  @property NSString *disableUNAuthorizationOptionProvisional;
@end

@implementation AppboyPlugin

- (void)pluginInitialize {
  NSDictionary *settings = self.commandDelegate.settings;
  self.APIKey = settings[@"com.appboy.api_key"];
  self.disableAutomaticPushRegistration = settings[@"com.appboy.ios_disable_automatic_push_registration"];
  self.disableAutomaticPushHandling = settings[@"com.appboy.ios_disable_automatic_push_handling"];
  self.apiEndpoint = settings[@"com.appboy.ios_api_endpoint"];
  self.enableIDFACollection = settings[@"com.appboy.ios_enable_idfa_automatic_collection"];
  self.enableLocationCollection = settings[@"com.appboy.enable_location_collection"];
  self.enableGeofences = settings[@"com.appboy.geofences_enabled"];
  self.disableUNAuthorizationOptionProvisional = settings[@"com.appboy.ios_disable_un_authorization_option_provisional"];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFinishLaunchingListener:) name:UIApplicationDidFinishLaunchingNotification object:nil];
  if (![self.disableAutomaticPushHandling isEqualToString:@"YES"]) {
    [AppDelegate swizzleHostAppDelegate];
  }
}

- (void)didFinishLaunchingListener:(NSNotification *)notification {
  NSMutableDictionary *appboyLaunchOptions = [@{ABKSDKFlavorKey : @(CORDOVA)} mutableCopy];

  // Set location collection and geofences from preferences
  appboyLaunchOptions[ABKEnableAutomaticLocationCollectionKey] = self.enableLocationCollection;
  appboyLaunchOptions[ABKEnableGeofencesKey] = self.enableGeofences;

  // Add the endpoint only if it's non nil
  if (self.apiEndpoint != nil) {
    appboyLaunchOptions[ABKEndpointKey] = self.apiEndpoint;
  }

  // Set the IDFA delegate for the plugin
  if ([self.enableIDFACollection isEqualToString:@"YES"]) {
    NSLog(@"IDFA collection enabled. Using plugin IDFA delegate.");
    IDFADelegate *idfaDelegate = [[IDFADelegate alloc] init];
    appboyLaunchOptions[ABKIDFADelegateKey] = idfaDelegate;
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
      UNAuthorizationOptions options = UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge;
      if (@available(iOS 12.0, *)) {
        if (![self.disableUNAuthorizationOptionProvisional isEqualToString:@"YES"]) {
          options = options | UNAuthorizationOptionProvisional;
        }
      }
      [center requestAuthorizationWithOptions:options
                            completionHandler:^(BOOL granted, NSError *_Nullable error) {
                              [[Appboy sharedInstance] pushAuthorizationFromUserNotificationCenter:granted];
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
- (void)changeUser:(CDVInvokedUrlCommand *)command {
  NSString *userId = [command argumentAtIndex:0 withDefault:nil];
  [[Appboy sharedInstance] changeUser:userId];
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

- (void)disableSdk:(CDVInvokedUrlCommand *)command {
  [Appboy disableSDK];
}

- (void)enableSdk:(CDVInvokedUrlCommand *)command {
  [Appboy requestEnableSDKOnNextAppRun];
}

- (void)wipeData:(CDVInvokedUrlCommand *)command {
  [Appboy wipeDataAndDisableForAppRun];
}

- (void)requestImmediateDataFlush:(CDVInvokedUrlCommand *)command {
  [[Appboy sharedInstance] flushDataAndProcessRequestQueue];
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

- (void) addAlias:(CDVInvokedUrlCommand *)command {
  NSString *aliasName = [command argumentAtIndex:0 withDefault:nil];
  NSString *aliasLabel = [command argumentAtIndex:1 withDefault:nil];
  if (aliasName != nil && aliasLabel != nil) {
    [[Appboy sharedInstance].user addAlias:aliasName withLabel:aliasLabel];
  }
}

- (void) setLanguage:(CDVInvokedUrlCommand *)command {
  NSString *language = [command argumentAtIndex:0 withDefault:nil];
  if (language != nil) {
    [Appboy sharedInstance].user.language = language;
  }
}

- (void) getDeviceId:(CDVInvokedUrlCommand *)command {
  NSString *deviceId = [[Appboy sharedInstance] getDeviceId];
  [self sendCordovaSuccessPluginResultWithString:deviceId andCommand:command];
}

/*-------Appboy UI-------*/
- (void) launchNewsFeed:(CDVInvokedUrlCommand *)command {
  ABKNewsFeedViewController *newsFeed = [[ABKNewsFeedViewController alloc] init];
  [self.viewController presentViewController:newsFeed animated:YES completion:nil];
}

- (void) launchContentCards:(CDVInvokedUrlCommand *)command {
  [[Appboy sharedInstance] requestContentCardsRefresh];
  ABKContentCardsViewController *contentCardsModal = [[ABKContentCardsViewController alloc] init];
  UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
  UIViewController *mainViewController = keyWindow.rootViewController;
  [mainViewController presentViewController:contentCardsModal animated:YES completion:nil];
}

/*-------News Feed-------*/
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

/*-------Content Cards-------*/
- (void) requestContentCardsRefresh:(CDVInvokedUrlCommand *)command {
  [[Appboy sharedInstance] requestContentCardsRefresh];
}

- (void) logContentCardClicked:(CDVInvokedUrlCommand *)command {
  NSString *idString = [command argumentAtIndex:0 withDefault:nil];
  ABKContentCard *cardToClick = [self getContentCardById:idString];
  if (cardToClick) {
    [cardToClick logContentCardClicked];
  }
}

- (void) logContentCardDismissed:(CDVInvokedUrlCommand *)command {
  NSString *idString = [command argumentAtIndex:0 withDefault:nil];
  ABKContentCard *cardToClick = [self getContentCardById:idString];
  if (cardToClick) {
    [cardToClick logContentCardDismissed];
  }
}

- (void) logContentCardImpression:(CDVInvokedUrlCommand *)command {
  NSString *idString = [command argumentAtIndex:0 withDefault:nil];
  ABKContentCard *cardToClick = [self getContentCardById:idString];
  if (cardToClick) {
    [cardToClick logContentCardImpression];
  }
}

- (void) logContentCardsDisplayed:(CDVInvokedUrlCommand *)command {
  [[Appboy sharedInstance] logContentCardsDisplayed];
}

- (void) getContentCardsFromServer:(CDVInvokedUrlCommand *)command {
  NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
  NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
  [center addObserverForName:ABKContentCardsProcessedNotification object:nil
                                                   queue:mainQueue usingBlock:^(NSNotification *note) {
                                                     NSLog(@"Got Content Cards from server callback");
                                                     BOOL updateIsSuccessful = [note.userInfo[ABKContentCardsProcessedIsSuccessfulKey] boolValue];
                                                     if (updateIsSuccessful) {
                                                       [self getContentCardsFromCache:command];
                                                     }
                                                   }];
  [[Appboy sharedInstance] requestContentCardsRefresh];
}

- (void) getContentCardsFromCache:(CDVInvokedUrlCommand *)command {
  NSArray<ABKContentCard *> *cards = [[Appboy sharedInstance].contentCardsController getContentCards];

  NSMutableArray *mappedCards = [NSMutableArray arrayWithCapacity:[cards count]];
  [cards enumerateObjectsUsingBlock:^(id card, NSUInteger idx, BOOL *stop) {
     [mappedCards addObject:[AppboyPlugin RCTFormatContentCard:card]];
  }];

  [self sendCordovaSuccessPluginResultWithArray:mappedCards andCommand:command];
}

- (nullable ABKContentCard *)getContentCardById:(NSString *)idString {
  NSArray<ABKContentCard *> *cards = [[Appboy sharedInstance].contentCardsController getContentCards];
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"idString == %@", idString];
  NSArray *filteredArray = [cards filteredArrayUsingPredicate:predicate];

  if (filteredArray.count) {
    return filteredArray[0];
  }

  return nil;
}

+ (NSDictionary *) RCTFormatContentCard:(ABKContentCard *)card {
  NSMutableDictionary *formattedContentCardData = [NSMutableDictionary dictionary];

  formattedContentCardData[@"id"] = card.idString;
  formattedContentCardData[@"created"] = @(card.created);
  formattedContentCardData[@"expiresAt"] = @(card.expiresAt);
  formattedContentCardData[@"viewed"] = @(card.viewed);
  formattedContentCardData[@"clicked"] = @(card.clicked);
  formattedContentCardData[@"pinned"] = @(card.pinned);
  formattedContentCardData[@"dismissed"] = @(card.dismissed);
  formattedContentCardData[@"dismissible"] = @(card.dismissible);
  formattedContentCardData[@"url"] = card.urlString ?: [NSNull null];
  formattedContentCardData[@"openURLInWebView"] = @(card.openUrlInWebView);

  formattedContentCardData[@"extras"] = [AppboyPlugin getJsonFromExtras:card.extras];

  if ([card isKindOfClass:[ABKCaptionedImageContentCard class]]) {
    ABKCaptionedImageContentCard *captionedCard = (ABKCaptionedImageContentCard *)card;
    formattedContentCardData[@"image"] = captionedCard.image;
    formattedContentCardData[@"imageAspectRatio"] = @(captionedCard.imageAspectRatio);
    formattedContentCardData[@"title"] = captionedCard.title;
    formattedContentCardData[@"cardDescription"] = captionedCard.cardDescription;
    formattedContentCardData[@"domain"] = captionedCard.domain ?: [NSNull null];
    formattedContentCardData[@"type"] = @"Captioned";
  }

  if ([card isKindOfClass:[ABKBannerContentCard class]]) {
    ABKBannerContentCard *bannerCard = (ABKBannerContentCard *)card;
    formattedContentCardData[@"image"] = bannerCard.image;
    formattedContentCardData[@"imageAspectRatio"] = @(bannerCard.imageAspectRatio);
    formattedContentCardData[@"type"] = @"Banner";
  }

  if ([card isKindOfClass:[ABKClassicContentCard class]]) {
    ABKClassicContentCard *classicCard = (ABKClassicContentCard *)card;
    formattedContentCardData[@"image"] = classicCard.image ?: [NSNull null];
    formattedContentCardData[@"title"] = classicCard.title;
    formattedContentCardData[@"cardDescription"] = classicCard.cardDescription;
    formattedContentCardData[@"domain"] = classicCard.domain ?: [NSNull null];
    formattedContentCardData[@"type"] = @"Classic";
  }

  return formattedContentCardData;
}

+ (NSString *) getJsonFromExtras:(NSDictionary *)extras {
  NSError *error;
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:extras
                                                     options:0
                                                       error:&error];

  if (!jsonData) {
    NSLog(@"Got an error in getJsonFromExtras: %@", error);
    return @"{}";
  } else {
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
  }
}

- (void) sendCordovaErrorPluginResultWithString:(NSString *)resultMessage andCommand:(CDVInvokedUrlCommand *)command {
  CDVPluginResult *pluginResult = nil;
  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:resultMessage];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) sendCordovaSuccessPluginResultWithString:(NSString *)resultMessage andCommand:(CDVInvokedUrlCommand *)command {
  CDVPluginResult *pluginResult = nil;
  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:resultMessage];
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
