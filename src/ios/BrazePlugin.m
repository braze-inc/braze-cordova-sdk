#import "BrazePlugin.h"
#import "AppDelegate+Braze.h"

@import BrazeKit;
@import BrazeLocation;
@import BrazeUI;
@import UserNotifications;

@interface BrazePlugin()
  @property NSString *APIKey;
  @property NSString *disableAutomaticPushRegistration;
  @property NSString *disableAutomaticPushHandling;
  @property NSString *apiEndpoint;
  @property NSString *enableIDFACollection;
  @property NSString *enableLocationCollection;
  @property NSString *enableGeofences;
  @property NSString *disableUNAuthorizationOptionProvisional;
  @property NSString *sessionTimeout;
@end

@implementation BrazePlugin

- (void)pluginInitialize {
  NSDictionary *settings = self.commandDelegate.settings;
  self.APIKey = settings[@"com.braze.api_key"];
  self.disableAutomaticPushRegistration = settings[@"com.braze.ios_disable_automatic_push_registration"];
  self.disableAutomaticPushHandling = settings[@"com.braze.ios_disable_automatic_push_handling"];
  self.apiEndpoint = settings[@"com.braze.ios_api_endpoint"];
  self.enableIDFACollection = settings[@"com.braze.ios_enable_idfa_automatic_collection"];
  self.enableLocationCollection = settings[@"com.braze.enable_location_collection"];
  self.enableGeofences = settings[@"com.braze.geofences_enabled"];
  self.disableUNAuthorizationOptionProvisional = settings[@"com.braze.ios_disable_un_authorization_option_provisional"];
  self.sessionTimeout = settings[@"com.braze.ios_session_timeout"];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFinishLaunchingListener:) name:UIApplicationDidFinishLaunchingNotification object:nil];

  if (![self.disableAutomaticPushHandling isEqualToString:@"YES"]) {
    [AppDelegate swizzleHostAppDelegate];
  }
}

- (void)didFinishLaunchingListener:(NSNotification *)notification {
  BRZConfiguration *configuration = [[BRZConfiguration alloc] initWithApiKey:self.APIKey
                                                                    endpoint:self.apiEndpoint];
  [configuration.api setSdkFlavor:BRZSDKFlavorCordova];
  
  // Set location collection and geofences from preferences
  [configuration.location setGeofencesEnabled:self.enableGeofences];
  [configuration.location setAutomaticLocationCollection:self.enableLocationCollection];

  // Set the time interval for session time out (in seconds)
  NSNumber *timeout = [[[NSNumberFormatter alloc] init] numberFromString:self.sessionTimeout];
  [configuration setSessionTimeout:[timeout doubleValue]];
  [configuration.api addSDKMetadata:@[[BRZSDKMetadata cordova]]];
  self.braze = [[Braze alloc] initWithConfiguration:configuration];
  self.braze.inAppMessagePresenter = [[BrazeInAppMessageUI alloc] init];
  self.subscriptions = [NSMutableArray array];
  
  // Set the IDFA delegate for the plugin
  if ([self.enableIDFACollection isEqualToString:@"YES"]) {
    NSLog(@"IDFA collection enabled. Setting values for ad tracking.");
    [self.braze setIdentifierForAdvertiser:[self.idfaDelegate advertisingIdentifierString]];
    [self.braze setAdTrackingEnabled:[self.idfaDelegate isAdvertisingTrackingEnabledOrATTAuthorized]];
  }

  if (![self.disableAutomaticPushRegistration isEqualToString:@"YES"]) {
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
      // Braze automatically retrieves the push notification authorization settings after the user interacts with the permission prompt.
      if (error) {
        NSLog(@"%@", error.debugDescription);
      } else {
        NSLog(@"Notification authorization successfully requested.");
      }
    }];
    [[UIApplication sharedApplication] registerForRemoteNotifications];
  }
}

/*-------Braze-------*/
- (void)changeUser:(CDVInvokedUrlCommand *)command {
  NSString *userId = [command argumentAtIndex:0 withDefault:nil];
  [self.braze changeUser:userId];
}

- (void)logCustomEvent:(CDVInvokedUrlCommand *)command {
  NSString *customEventName = [command argumentAtIndex:0 withDefault:nil];
  NSDictionary *properties = [command argumentAtIndex:1 withDefault:nil];
  [self.braze logCustomEvent:customEventName
                  properties:properties];
}

- (void)logPurchase:(CDVInvokedUrlCommand *)command {
  NSString *purchaseName = [command argumentAtIndex:0 withDefault:nil];
  NSString *currency = [command argumentAtIndex:2 withDefault:@"USD"];
  NSString *price = [[command argumentAtIndex:1 withDefault:nil] stringValue];
  NSUInteger quantity = [[command argumentAtIndex:3 withDefault:@1] integerValue];
  NSDictionary *properties = [command argumentAtIndex:4 withDefault:nil];
  [self.braze logPurchase:purchaseName
                 currency:currency
                    price:[[NSDecimalNumber decimalNumberWithString:price] doubleValue]
                 quantity:quantity
               properties:properties];
}

- (void)disableSdk:(CDVInvokedUrlCommand *)command {
  [self.braze setEnabled:NO];
}

- (void)enableSdk:(CDVInvokedUrlCommand *)command {
  [self.braze _requestEnableSDKOnNextAppRun];
}

- (void)wipeData:(CDVInvokedUrlCommand *)command {
  [self.braze wipeData];
}

- (void)requestImmediateDataFlush:(CDVInvokedUrlCommand *)command {
  [self.braze requestImmediateDataFlush];
}

/*-------Braze.User-------*/
- (void)setFirstName:(CDVInvokedUrlCommand *)command {
  NSString *firstName = [command argumentAtIndex:0 withDefault:nil];
  [self.braze.user setFirstName:firstName];
}

- (void)setLastName:(CDVInvokedUrlCommand *)command {
  NSString *lastName = [command argumentAtIndex:0 withDefault:nil];
  [self.braze.user setLastName:lastName];
}

- (void)setEmail:(CDVInvokedUrlCommand *)command {
  NSString *email = [command argumentAtIndex:0 withDefault:nil];
  [self.braze.user setEmail:email];
}

- (void)setGender:(CDVInvokedUrlCommand *)command {
  NSString *gender = [command argumentAtIndex:0 withDefault:nil];
  if ([gender.lowercaseString isEqualToString:@"f"]) {
    [self.braze.user setGender:BRZUserGender.female];
  } else if ([gender.lowercaseString isEqualToString:@"m"]) {
    [self.braze.user setGender:BRZUserGender.male];
  } else if ([gender.lowercaseString isEqualToString:@"n"]) {
    [self.braze.user setGender:BRZUserGender.notApplicable];
  } else if ([gender.lowercaseString isEqualToString:@"o"]) {
    [self.braze.user setGender:BRZUserGender.other];
  } else if ([gender.lowercaseString isEqualToString:@"p"]) {
    [self.braze.user setGender:BRZUserGender.preferNotToSay];
  } else if ([gender.lowercaseString isEqualToString:@"u"]) {
    [self.braze.user setGender:BRZUserGender.unknown];
  }
}

- (void)setDateOfBirth:(CDVInvokedUrlCommand *)command {
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
    [self.braze.user setDateOfBirth:date];
  }
}

- (void)setCountry:(CDVInvokedUrlCommand *)command {
  NSString *country = [command argumentAtIndex:0 withDefault:nil];
  [self.braze.user setCountry:country];
}

- (void)setHomeCity:(CDVInvokedUrlCommand *)command {
  NSString *homeCity = [command argumentAtIndex:0 withDefault:nil];
  [self.braze.user setHomeCity:homeCity];
}

- (void)setPhoneNumber:(CDVInvokedUrlCommand *)command {
  NSString *phone = [command argumentAtIndex:0 withDefault:nil];
  [self.braze.user setPhoneNumber:phone];
}

- (void)setPushNotificationSubscriptionType:(CDVInvokedUrlCommand *)command {
  NSString *subscriptionState = [command argumentAtIndex:0 withDefault:nil];
  [self.braze.user setPushNotificationSubscriptionState:[self getSubscriptionStateFromString:subscriptionState]];
}

- (void)setEmailNotificationSubscriptionType:(CDVInvokedUrlCommand *)command {
  NSString *subscriptionState = [command argumentAtIndex:0 withDefault:nil];
  [self.braze.user setEmailSubscriptionState:[self getSubscriptionStateFromString:subscriptionState]];
}

- (void)setUserAttributionData:(CDVInvokedUrlCommand *)command {
  BRZUserAttributionData *attributionData = [[BRZUserAttributionData alloc]
                                             initWithNetwork:[command argumentAtIndex:0 withDefault:nil]
                                             campaign:[command argumentAtIndex:1 withDefault:nil]
                                             adGroup:[command argumentAtIndex:2 withDefault:nil]
                                             creative:[command argumentAtIndex:3 withDefault:nil]];
  [self.braze.user setAttributionData:attributionData];
}

- (BRZUserSubscriptionState)getSubscriptionStateFromString:(NSString *)stateString {
  if ([stateString.lowercaseString isEqualToString:@"opted_in"]) {
    return BRZUserSubscriptionStateOptedIn;
  } else if ([stateString.lowercaseString isEqualToString:@"unsubscribed"]) {
    return BRZUserSubscriptionStateUnsubscribed;
  } else {
    return BRZUserSubscriptionStateSubscribed;
  }
}

- (void)setBoolCustomUserAttribute:(CDVInvokedUrlCommand *)command {
  NSString *key = [command argumentAtIndex:0 withDefault:nil];
  NSString *value = [command argumentAtIndex:1 withDefault:nil];
  if (key != nil && value != nil) {
    [self.braze.user setCustomAttributeWithKey:key boolValue:[value boolValue]];
  }
}

- (void)setStringCustomUserAttribute:(CDVInvokedUrlCommand *)command {
  NSString *key = [command argumentAtIndex:0 withDefault:nil];
  NSString *value = [command argumentAtIndex:1 withDefault:nil];
  if (key != nil && value != nil) {
    [self.braze.user setCustomAttributeWithKey:key stringValue:value];
  }
}

- (void)setDoubleCustomUserAttribute:(CDVInvokedUrlCommand *)command {
  NSString *key = [command argumentAtIndex:0 withDefault:nil];
  NSString *value = [command argumentAtIndex:1 withDefault:nil];
  if (key != nil && value != nil) {
    [self.braze.user setCustomAttributeWithKey:key doubleValue:[value doubleValue]];
  }
}

- (void)setDateCustomUserAttribute:(CDVInvokedUrlCommand *)command {
  NSString *key = [command argumentAtIndex:0 withDefault:nil];
  NSString *value = [command argumentAtIndex:1 withDefault:nil];
  if (key != nil && value != nil) {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[value longLongValue]];
    [self.braze.user setCustomAttributeWithKey:key dateValue:date];
  }
}

- (void)setIntCustomUserAttribute:(CDVInvokedUrlCommand *)command {
  NSString *key = [command argumentAtIndex:0 withDefault:nil];
  NSString *value = [command argumentAtIndex:1 withDefault:nil];
  if (key != nil && value != nil) {
    [self.braze.user setCustomAttributeWithKey:key intValue:[value integerValue]];
  }
}

- (void)setCustomUserAttributeArray:(CDVInvokedUrlCommand *)command {
  NSString *key = [command argumentAtIndex:0 withDefault:nil];
  id value = [command argumentAtIndex:1 withDefault:nil];
  if (key != nil && value != nil && [value isKindOfClass:[NSArray class]]) {
    [self.braze.user setCustomAttributeArrayWithKey:key array:value];
  }
}

- (void)unsetCustomUserAttribute:(CDVInvokedUrlCommand *)command {
  NSString *key = [command argumentAtIndex:0 withDefault:nil];
  if (key != nil) {
    [self.braze.user unsetCustomAttributeWithKey:key];
  }
}

- (void)incrementCustomUserAttribute:(CDVInvokedUrlCommand *)command {
  NSString *key = [command argumentAtIndex:0 withDefault:nil];
  NSString *incrementValue = [command argumentAtIndex:1 withDefault:@1];
  if (key != nil) {
    [self.braze.user incrementCustomUserAttribute:key by:[incrementValue integerValue]];
  }
}

- (void)addToCustomAttributeArray:(CDVInvokedUrlCommand *)command {
  NSString *key = [command argumentAtIndex:0 withDefault:nil];
  NSString *value = [command argumentAtIndex:1 withDefault:nil];
  if (key != nil && value != nil) {
    [self.braze.user addToCustomAttributeArrayWithKey:key value:value];
  }
}

- (void)removeFromCustomAttributeArray:(CDVInvokedUrlCommand *)command {
  NSString *key = [command argumentAtIndex:0 withDefault:nil];
  NSString *value = [command argumentAtIndex:1 withDefault:nil];
  if (key != nil && value != nil) {
    [self.braze.user removeFromCustomAttributeArrayWithKey:key value:value];
  }
}

- (void)addAlias:(CDVInvokedUrlCommand *)command {
  NSString *aliasName = [command argumentAtIndex:0 withDefault:nil];
  NSString *aliasLabel = [command argumentAtIndex:1 withDefault:nil];
  if (aliasName != nil && aliasLabel != nil) {
    [self.braze.user addAlias:aliasName label:aliasLabel];
  }
}

- (void)setLanguage:(CDVInvokedUrlCommand *)command {
  NSString *language = [command argumentAtIndex:0 withDefault:nil];
  if (language != nil) {
    [self.braze.user setLanguage:language];
  }
}

- (void)addToSubscriptionGroup:(CDVInvokedUrlCommand *)command {
  NSString *groupId = [command argumentAtIndex:0 withDefault:nil];
  if (groupId != nil) {
    [self.braze.user addToSubscriptionGroupWithGroupId:groupId];
  }
}

- (void)removeFromSubscriptionGroup:(CDVInvokedUrlCommand *)command {
  NSString *groupId = [command argumentAtIndex:0 withDefault:nil];
  if (groupId != nil) {
    [self.braze.user removeFromSubscriptionGroupWithGroupId:groupId];
  }
}

- (void)getDeviceId:(CDVInvokedUrlCommand *)command {
  [self.braze deviceIdWithCompletion:^(NSString *deviceId) {
    [self sendCordovaSuccessPluginResultWithString:deviceId andCommand:command];
  }];
}

/*-------BrazeUI-------*/
- (void)launchNewsFeed:(CDVInvokedUrlCommand *)command {
  NSLog(@"News Feed UI not supported on iOS.");
}

- (void)launchContentCards:(CDVInvokedUrlCommand *)command {
  [self.braze.contentCards requestRefresh];
  
  BRZContentCardUIModalViewController *contentCardsModal = [[BRZContentCardUIModalViewController alloc] initWithBraze:self.braze];
  UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
  UIViewController *mainViewController = keyWindow.rootViewController;
  [mainViewController presentViewController:contentCardsModal animated:YES completion:nil];
}

/*-------News Feed-------*/
- (void)getNewsFeed:(CDVInvokedUrlCommand *)command {
  [self.braze.newsFeed requestRefresh];
  NSArray *cardCategories = [self getCardCategoriesFromStringArray:command.arguments];
  int argumentsMask = [self getMaskFromCategories:cardCategories];

  if (argumentsMask == 0) {
    [self sendCordovaErrorPluginResultWithString:@"Category could not be set." andCommand:command];
    return;
  }
  
  NSMutableArray *mappedCards = [NSMutableArray array];
  NSError *e = nil;

  for (BRZNewsFeedCard *card_item in self.braze.newsFeed.cards) {
    int cardItemMask = [self getMaskFromCategories:card_item.categories];
    if ((argumentsMask & cardItemMask) == cardItemMask) {
      NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:[card_item json]
                                                           options:kNilOptions
                                                             error: &e];
      [mappedCards addObject:jsonArray];
    }
  }

  [self sendCordovaSuccessPluginResultWithArray:mappedCards andCommand:command];
}

- (void)getCardCountForCategories:(CDVInvokedUrlCommand *)command {
  NSArray *cardCategories = [self getCardCategoriesFromStringArray:command.arguments];
  int argumentsMask = [self getMaskFromCategories:cardCategories];

  if (argumentsMask == 0) {
    [self sendCordovaErrorPluginResultWithString:@"Category could not be set." andCommand:command];
    return;
  }
  
  NSInteger cardCount = 0;
  for (BRZNewsFeedCard *card_item in self.braze.newsFeed.cards) {
    int cardItemMask = [self getMaskFromCategories:card_item.categories];
    if ((argumentsMask & cardItemMask) == cardItemMask) {
      cardCount++;
    }
  }
  [self sendCordovaSuccessPluginResultWithInt:cardCount andCommand:command];
}

- (void)getUnreadCardCountForCategories:(CDVInvokedUrlCommand *)command {
  NSArray *cardCategories = [self getCardCategoriesFromStringArray:command.arguments];
  int argumentsMask = [self getMaskFromCategories:cardCategories];

  if (argumentsMask == 0) {
    [self sendCordovaErrorPluginResultWithString:@"Category could not be set." andCommand:command];
    return;
  }

  NSInteger unreadCardCount = 0;
  for (BRZNewsFeedCard *card in self.braze.newsFeed.cards) {
    if (card.viewed) {
      continue;
    }
    int cardItemMask = [self getMaskFromCategories:card.categories];
    if ((argumentsMask & cardItemMask) == cardItemMask) {
      unreadCardCount++;
    }
  }
  [self sendCordovaSuccessPluginResultWithInt:unreadCardCount andCommand:command];
}

- (NSArray *)getCardCategoriesFromStringArray:(NSArray *)categories {
  NSMutableArray *cardCategories = [NSMutableArray array];
  NSArray *allCases = @[
    [BRZNewsFeedCardCategory advertising],
    [BRZNewsFeedCardCategory announcements],
    [BRZNewsFeedCardCategory news],
    [BRZNewsFeedCardCategory social]
  ];
  if (categories != nil && categories.count > 0) {
    for (NSString *categoryString in categories) {
      if ([categoryString.lowercaseString isEqualToString:@"advertising"]) {
        [cardCategories addObject:[BRZNewsFeedCardCategory advertising]];
      } else if ([categoryString.lowercaseString isEqualToString:@"announcements"]) {
        [cardCategories addObject:[BRZNewsFeedCardCategory announcements]];
      } else if ([categoryString.lowercaseString isEqualToString:@"news"]) {
        [cardCategories addObject:[BRZNewsFeedCardCategory news]];
      } else if ([categoryString.lowercaseString isEqualToString:@"social"]) {
        [cardCategories addObject:[BRZNewsFeedCardCategory social]];
      } else if ([categoryString.lowercaseString isEqualToString:@"no_category"]) {
        [cardCategories addObject:[BRZNewsFeedCardCategory none]];
      } else if ([categoryString.lowercaseString isEqualToString:@"all"]) {
        return allCases;
      }
    }
  }
  return cardCategories;
}

- (int)getMaskFromCategories:(NSArray *)categories {
  int categoryMask = 0;
  if (categories != nil && categories.count > 0) {
    // Iterate over the categories and get the category mask
    for (BRZNewsFeedCardCategory *cardCategory in categories) {
      if ([cardCategory isEqual:[BRZNewsFeedCardCategory advertising]]) {
        categoryMask |= 1 << 2;
      } else if ([cardCategory isEqual:[BRZNewsFeedCardCategory announcements]]) {
        categoryMask |= 1 << 3;
      }  else if ([cardCategory isEqual:[BRZNewsFeedCardCategory news]]) {
        categoryMask |= 1 << 1;
      }  else if ([cardCategory isEqual:[BRZNewsFeedCardCategory social]]) {
        categoryMask |= 1 << 4;
      }  else if ([cardCategory isEqual:[BRZNewsFeedCardCategory none]]) {
        categoryMask |= 1 << 0;
      }
    }
  }
  return categoryMask;
}

/*-------Content Cards-------*/
- (void)requestContentCardsRefresh:(CDVInvokedUrlCommand *)command {
  [self.braze.contentCards requestRefresh];
}

- (void)logContentCardClicked:(CDVInvokedUrlCommand *)command {
  NSString *idString = [command argumentAtIndex:0 withDefault:nil];
  BRZContentCardRaw *cardToClick = [self getContentCardById:idString];
  if (cardToClick) {
    [cardToClick logClickUsing:self.braze];
  }
}

- (void)logContentCardDismissed:(CDVInvokedUrlCommand *)command {
  NSString *idString = [command argumentAtIndex:0 withDefault:nil];
  BRZContentCardRaw *cardToDismiss = [self getContentCardById:idString];
  if (cardToDismiss) {
    [cardToDismiss logDismissedUsing:self.braze];
  }
}

- (void)logContentCardImpression:(CDVInvokedUrlCommand *)command {
  NSString *idString = [command argumentAtIndex:0 withDefault:nil];
  BRZContentCardRaw *cardToView = [self getContentCardById:idString];
  if (cardToView) {
    [cardToView logImpressionUsing:self.braze];
  }
}

- (void)getContentCardsFromServer:(CDVInvokedUrlCommand *)command {
  [self.braze.contentCards requestRefreshWithCompletion:^(NSArray<BRZContentCardRaw *> * _Nullable cards, NSError * _Nullable error) {
    if (error) {
      NSLog(@"%@", error.debugDescription);
    } else {
      NSLog(@"Got Content Cards from server callback");
      [self getContentCardsFromCache:command];
    }
  }];
}

- (void)getContentCardsFromCache:(CDVInvokedUrlCommand *)command {
  NSArray<BRZContentCardRaw *> *cards = [self.braze.contentCards cards];

  NSMutableArray *mappedCards = [NSMutableArray arrayWithCapacity:[cards count]];
  [cards enumerateObjectsUsingBlock:^(id card, NSUInteger idx, BOOL *stop) {
     [mappedCards addObject:[BrazePlugin formattedContentCard:card]];
  }];

  [self sendCordovaSuccessPluginResultWithArray:mappedCards andCommand:command];
}

- (nullable BRZContentCardRaw *)getContentCardById:(NSString *)idString {
  NSArray<BRZContentCardRaw *> *cards = self.braze.contentCards.cards;
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", idString];
  NSArray *filteredArray = [cards filteredArrayUsingPredicate:predicate];

  if (filteredArray.count) {
    return filteredArray[0];
  }

  return nil;
}

+ (NSDictionary *)formattedContentCard:(BRZContentCardRaw *)card {
  NSMutableDictionary *formattedContentCardData = [NSMutableDictionary dictionary];
  
  formattedContentCardData[@"id"] = card.identifier;
  formattedContentCardData[@"created"] = @(card.createdAt);
  formattedContentCardData[@"expiresAt"] = @(card.expiresAt);
  formattedContentCardData[@"viewed"] = @(card.viewed);
  formattedContentCardData[@"clicked"] = @(card.clicked);
  formattedContentCardData[@"pinned"] = @(card.pinned);
  formattedContentCardData[@"dismissed"] = @(card.removed);
  formattedContentCardData[@"dismissible"] = @(card.dismissible);
  formattedContentCardData[@"url"] = [card.url absoluteString] ?: [NSNull null];
  formattedContentCardData[@"openURLInWebView"] = @(card.useWebView);
  
  if (card.extras != nil) {
    formattedContentCardData[@"extras"] = [BrazePlugin getJsonFromExtras:card.extras];
  }
  
  switch (card.type) {
    case BRZContentCardRawTypeClassic:
      formattedContentCardData[@"image"] = [card.image absoluteString] ?: [NSNull null];
      formattedContentCardData[@"title"] = card.title;
      formattedContentCardData[@"cardDescription"] = card.cardDescription;
      formattedContentCardData[@"domain"] = card.domain ?: [NSNull null];
      formattedContentCardData[@"type"] = @"Classic";
      break;
    case BRZContentCardRawTypeBanner:
      formattedContentCardData[@"image"] = [card.image absoluteString];
      formattedContentCardData[@"imageAspectRatio"] = @(card.imageAspectRatio);
      formattedContentCardData[@"type"] = @"Banner";
      break;
    case BRZContentCardRawTypeCaptionedImage:
      formattedContentCardData[@"image"] = [card.image absoluteString];
      formattedContentCardData[@"imageAspectRatio"] = @(card.imageAspectRatio);
      formattedContentCardData[@"title"] = card.title;
      formattedContentCardData[@"cardDescription"] = card.cardDescription;
      formattedContentCardData[@"domain"] = card.domain ?: [NSNull null];
      formattedContentCardData[@"type"] = @"Captioned";
      break;
    case BRZContentCardRawTypeControl:
      break;
  }

  return formattedContentCardData;
}

+ (NSString *)getJsonFromExtras:(NSDictionary *)extras {
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

/*-------Feature Flags-------*/
- (void)getFeatureFlag:(CDVInvokedUrlCommand *)command {
  NSString *featureFlagId = [command argumentAtIndex:0 withDefault:nil];
  BRZFeatureFlag *featureFlag = [self.braze.featureFlags featureFlagWithId:featureFlagId];
  
  NSError* error = nil;
  id flagJSON = [NSJSONSerialization JSONObjectWithData:[featureFlag json]
                                                options:NSJSONReadingMutableContainers
                                                  error:&error];
  if (error || flagJSON == nil) {
    [self sendCordovaErrorPluginResultWithString:error.debugDescription andCommand:command];
  } else {
    [self sendCordovaSuccessPluginResultWithDictionary:flagJSON andCommand:command];
  }
}

- (void)getAllFeatureFlags:(CDVInvokedUrlCommand *)command {
  [self sendCordovaSuccessPluginResultWithArray:[BrazePlugin formattedFeatureFlagsMap:self.braze.featureFlags.featureFlags]
                                     andCommand:command];
}

- (void)refreshFeatureFlags:(CDVInvokedUrlCommand *)command {
  [self.braze.featureFlags requestRefresh];
}

- (void)subscribeToFeatureFlagUpdates:(CDVInvokedUrlCommand *)command {
  [self.subscriptions addObject:[self.braze.featureFlags subscribeToUpdates:^(NSArray<BRZFeatureFlag *> * featureFlags) {
    NSArray<NSDictionary *> *mappedFlags = [BrazePlugin formattedFeatureFlagsMap:featureFlags];
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:mappedFlags];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
  }]];
}

- (void)getFeatureFlagBooleanProperty:(CDVInvokedUrlCommand *)command {
  NSString *featureFlagId = [command argumentAtIndex:0 withDefault:nil];
  NSString *propertyKey = [command argumentAtIndex:1 withDefault:nil];

  BRZFeatureFlag *featureFlag = [self.braze.featureFlags featureFlagWithId:featureFlagId];
  NSNumber *boolProperty = [featureFlag boolPropertyForKey:propertyKey];
  if (boolProperty) {
    [self sendCordovaSuccessPluginResultWithBool:boolProperty andCommand:command];
  } else {
    [self sendCordovaSuccessPluginResultAsNull:command];
  }
}

- (void)getFeatureFlagStringProperty:(CDVInvokedUrlCommand *)command {
  NSString *featureFlagId = [command argumentAtIndex:0 withDefault:nil];
  NSString *propertyKey = [command argumentAtIndex:1 withDefault:nil];

  BRZFeatureFlag *featureFlag = [self.braze.featureFlags featureFlagWithId:featureFlagId];
  NSString *stringProperty = [featureFlag stringPropertyForKey:propertyKey];
  if (stringProperty) {
    [self sendCordovaSuccessPluginResultWithString:stringProperty andCommand:command];
  } else {
    [self sendCordovaSuccessPluginResultAsNull:command];
  }
}

- (void)getFeatureFlagNumberProperty:(CDVInvokedUrlCommand *)command {
  NSString *featureFlagId = [command argumentAtIndex:0 withDefault:nil];
  NSString *propertyKey = [command argumentAtIndex:1 withDefault:nil];

  BRZFeatureFlag *featureFlag = [self.braze.featureFlags featureFlagWithId:featureFlagId];
  NSNumber *numberProperty = [featureFlag numberPropertyForKey:propertyKey];
  if (numberProperty) {
    [self sendCordovaSuccessPluginResultWithDouble:[numberProperty doubleValue] andCommand:command];
  } else {
    [self sendCordovaSuccessPluginResultAsNull:command];
  }
}

+ (NSArray<NSDictionary *> *)formattedFeatureFlagsMap:(NSArray<BRZFeatureFlag *> *)featureFlags {
  NSMutableArray<NSDictionary *> *mappedFlags = [NSMutableArray array];
  for (BRZFeatureFlag *flag in featureFlags) {
    NSError* error = nil;
    id flagJSON = [NSJSONSerialization JSONObjectWithData:[flag json]
                                                  options:NSJSONReadingMutableContainers
                                                    error:&error];
    if (!error) {
      [mappedFlags addObject:flagJSON];
    } else {
      NSLog(@"Failed to serialize Feature Flag with error: %@", error);
    }
  }
  
  return mappedFlags;
}

/*-------Cordova Helper Methods-------*/
- (void)sendCordovaErrorPluginResultWithString:(NSString *)resultMessage andCommand:(CDVInvokedUrlCommand *)command {
  CDVPluginResult *pluginResult = nil;
  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:resultMessage];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)sendCordovaSuccessPluginResultWithString:(NSString *)resultMessage andCommand:(CDVInvokedUrlCommand *)command {
  CDVPluginResult *pluginResult = nil;
  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:resultMessage];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)sendCordovaSuccessPluginResultWithInt:(NSUInteger)resultMessage andCommand:(CDVInvokedUrlCommand *)command {
  CDVPluginResult *pluginResult = nil;
  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:(int)resultMessage];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)sendCordovaSuccessPluginResultWithDouble:(double)resultMessage andCommand:(CDVInvokedUrlCommand *)command {
  CDVPluginResult *pluginResult = nil;
  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDouble:resultMessage];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)sendCordovaSuccessPluginResultWithBool:(BOOL)resultMessage andCommand:(CDVInvokedUrlCommand *)command {
  CDVPluginResult *pluginResult = nil;
  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:resultMessage];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)sendCordovaSuccessPluginResultWithArray:(NSArray *)resultMessage andCommand:(CDVInvokedUrlCommand *)command {
  CDVPluginResult *pluginResult = nil;
  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:resultMessage];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)sendCordovaSuccessPluginResultWithDictionary:(NSDictionary *)resultMessage andCommand:(CDVInvokedUrlCommand *)command {
  CDVPluginResult *pluginResult = nil;
  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:resultMessage];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)sendCordovaSuccessPluginResultAsNull:(CDVInvokedUrlCommand *)command {
  CDVPluginResult *pluginResult = nil;
  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:(NSString *)[NSNull null]];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

@end
