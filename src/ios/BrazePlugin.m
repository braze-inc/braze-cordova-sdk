#import "BrazePlugin.h"
#import "AppDelegate+Braze.h"

@import BrazeKit;
@import BrazeLocation;
@import BrazeUI;
@import UserNotifications;

@interface BrazePlugin() <BrazeSDKAuthDelegate, BrazeInAppMessageUIDelegate>
  @property NSString *APIKey;
  @property NSString *disableAutomaticPushRegistration;
  @property NSString *disableAutomaticPushHandling;
  @property NSString *apiEndpoint;
  @property NSString *enableIDFACollection;
  @property NSString *enableLocationCollection;
  @property NSString *enableGeofences;
  @property NSString *disableUNAuthorizationOptionProvisional;
  @property NSString *sessionTimeout;
  @property NSString *enableSDKAuth;
  @property NSString *sdkAuthCallbackID;
  @property NSString *triggerActionMinimumTimeInterval;
  @property NSString *pushAppGroup;
  @property NSString *forwardUniversalLinks;
  @property NSString *logLevel;
  @property NSString *useUUIDAsDeviceId;
  @property NSString *flushInterval;
  @property NSString *useAutomaticRequestPolicy;
  @property NSString *optInWhenPushAuthorized;
@end

static Braze *_braze;

@implementation BrazePlugin

bool isInAppMessageSubscribed;

+ (Braze *)braze {
  return _braze;
}

+ (void)setBraze:(Braze *)braze {
  _braze = braze;
}

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
  self.enableSDKAuth = settings[@"com.braze.sdk_authentication_enabled"];
  self.triggerActionMinimumTimeInterval = settings[@"com.braze.trigger_action_minimum_time_interval_seconds"];
  self.pushAppGroup = settings[@"com.braze.ios_push_app_group"];
  self.forwardUniversalLinks = settings[@"com.braze.ios_forward_universal_links"];
  self.logLevel = settings[@"com.braze.ios_log_level"];
  self.useUUIDAsDeviceId = settings[@"com.braze.ios_use_uuid_as_device_id"];
  self.flushInterval = settings[@"com.braze.ios_flush_interval_seconds"];
  self.useAutomaticRequestPolicy = settings[@"com.braze.ios_use_automatic_request_policy"];
  self.optInWhenPushAuthorized = settings[@"com.braze.should_opt_in_when_push_authorized"];
  isInAppMessageSubscribed = NO;

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFinishLaunchingListener:) name:UIApplicationDidFinishLaunchingNotification object:nil];

  // Set automatic push handling
  if (![[self sanitizeString:self.disableAutomaticPushHandling] isEqualToString:@"yes"]) {
    [AppDelegate swizzleHostAppDelegate];
    NSLog(@"Automatic push handling enabled.");
  } else {
    NSLog(@"Automatic push handling disabled.");
  }
}

- (void)didFinishLaunchingListener:(NSNotification *)notification {
  BRZConfiguration *configuration = [[BRZConfiguration alloc] initWithApiKey:self.APIKey
                                                                    endpoint:self.apiEndpoint];
  
  // Set SDK Flavor
  [configuration.api setSdkFlavor:BRZSDKFlavorCordova];
  
  // Set the minimum logging level
  NSNumber *level = [[[NSNumberFormatter alloc] init] numberFromString:self.logLevel];
  NSInteger levelCast = [level integerValue];
  if (level && levelCast >= 0 && levelCast <= 3) {
    [configuration.logger setLevel:(BRZLoggerLevel)levelCast];
    NSLog(@"Log level set to: %hhu", (BRZLoggerLevel)levelCast);
  } else {
    NSLog(@"Log level value not valid. Setting value to: error (2).");
  }

  // Set location collection from preferences
  if ([[self sanitizeString:self.enableLocationCollection] isEqualToString:@"yes"]) {
    configuration.location.automaticLocationCollection = @YES;
    NSLog(@"Location collection enabled.");
  } else {
    NSLog(@"Location collection disabled.");
  }
  
  // Set geofences from preferences
  if ([[self sanitizeString:self.enableGeofences] isEqualToString:@"yes"]) {
    configuration.location.geofencesEnabled = @YES;
    NSLog(@"Geofences enabled.");
  } else {
    NSLog(@"Geofences disabled.");
  }
  
  // Set the minimum time interval between triggers (in seconds)
  NSNumber *interval = [[[NSNumberFormatter alloc] init] numberFromString:self.triggerActionMinimumTimeInterval];
  NSTimeInterval intervalCast = [interval doubleValue];
  if (interval && intervalCast >= 0) {
    [configuration setTriggerMinimumTimeInterval:intervalCast];
    NSLog(@"Minimum time interval between trigger actions set to: %f", intervalCast);
  } else {
    NSLog(@"Minimum time interval between trigger actions value not valid. Setting value to 30.");
  }
  
  // Sets if a randomly generated UUID should be used as the device ID
  if ([[self sanitizeString:self.useUUIDAsDeviceId] isEqualToString:@"yes"]) {
    configuration.useUUIDAsDeviceId = @YES;
    NSLog(@"Using UUID as Device ID enabled.");
  } else {
    NSLog(@"Using UUID as Device ID disabled.");
  }

  // Set if the SDK should automatically recognize and forward universal links to the system methods
  if ([[self sanitizeString:self.forwardUniversalLinks] isEqualToString:@"yes"]) {
    configuration.forwardUniversalLinks = @YES;
    NSLog(@"iOS universal link forwarding enabled.");
  } else {
    NSLog(@"iOS universal link forwarding disabled.");
  }
  
  // Set if a user’s notification subscription state should be set to optedIn when push permissions are authorized
  if ([[self sanitizeString:self.optInWhenPushAuthorized] isEqualToString:@"no"]) {
    configuration.optInWhenPushAuthorized = @NO;
    NSLog(@"User notification subscription state not automatically optedIn when push is authorized.");
  } else {
    NSLog(@"User notification subscription state automatically optedIn when push is authorized.");
  }

  // Set the time interval for session time out (in seconds)
  NSNumber *timeout = [[[NSNumberFormatter alloc] init] numberFromString:self.sessionTimeout];
  NSTimeInterval timeoutCast = [timeout doubleValue];
  if (timeout && timeoutCast >= 0) {
    [configuration setSessionTimeout:timeoutCast];
    NSLog(@"Session timeout interval set to: %f", timeoutCast);
  } else {
    NSLog(@"Session timeout interval value not valid. Setting value to 10.");
  }
  
  // Set SDK Metadata
  [configuration.api addSDKMetadata:@[[BRZSDKMetadata cordova]]];
  NSLog(@"SDK Metadata set.");
  
  // Set if request policy should be automatic or manual
  if ([[self sanitizeString: self.useAutomaticRequestPolicy] isEqualToString:@"no"]) {
    [configuration.api setRequestPolicy:BRZRequestPolicyManual];
    NSLog(@"Request policy set to: Manual.");
  } else {
    NSLog(@"Request policy set to: Automatic.");
  }
  
  // Set the interval in seconds between automatic data flushes
  NSNumber *flushInterval = [[[NSNumberFormatter alloc] init] numberFromString:self.flushInterval];
  NSTimeInterval flushIntervalCast = [flushInterval doubleValue];
  if (flushInterval && flushIntervalCast >= 0) {
    [configuration.api setFlushInterval:flushIntervalCast];
    NSLog(@"Flush interval set to: %f", flushIntervalCast);
  } else {
    NSLog(@"Flush interval value not valid. Setting value to 10.");
  }

  // Set the app group identifier for push stories.
  [configuration.push setAppGroup:self.pushAppGroup];
  NSLog(@"Push app group set to: %@.", self.pushAppGroup);
  
  // Initialize Braze with set configurations
  self.braze = [[Braze alloc] initWithConfiguration:configuration];
  self.subscriptions = [NSMutableArray array];
  [BrazePlugin setBraze:self.braze];
  NSLog(@"Braze initialized with set configurations.");

  // In-App Message UI
  BrazeInAppMessageUI *inAppMessageUI = [[BrazeInAppMessageUI alloc] init];
  inAppMessageUI.delegate = self;
  self.braze.inAppMessagePresenter = inAppMessageUI;

  // Set the IDFA delegate for the plugin
  if ([[self sanitizeString:self.enableIDFACollection] isEqualToString:@"yes"]) {
    NSLog(@"IDFA collection enabled. Setting values for ad tracking.");
    [self.braze setIdentifierForAdvertiser:[self.idfaDelegate advertisingIdentifierString]];
    [self.braze setAdTrackingEnabled:[self.idfaDelegate isAdvertisingTrackingEnabledOrATTAuthorized]];
  } else {
    NSLog(@"IDFA collection disabled.");
  }

  // Set the SDK authentication delegate
  if ([[self sanitizeString:self.enableSDKAuth] isEqualToString:@"yes"]) {
    NSLog(@"SDK authentication enabled. To receive and handle authentication errors, call `subscribeToSdkAuthenticationFailures`.");
    self.braze.sdkAuthDelegate = self;
  } else {
    NSLog(@"SDK authentication disabled.");
  }

  // Set automatic push registration and request notification authorization
  if (![[self sanitizeString:self.disableAutomaticPushRegistration] isEqualToString:@"yes"]) {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    // If the delegate hasn't been set yet, set it here in the plugin
    if (center.delegate == nil) {
      center.delegate = [UIApplication sharedApplication].delegate;
    }
    UNAuthorizationOptions options = UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge;
    if (@available(iOS 12.0, *)) {
      if (![[self sanitizeString:self.disableUNAuthorizationOptionProvisional] isEqualToString:@"yes"]) {
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
    NSLog(@"Automatic push registration enabled.");
  } else {
    NSLog(@"Automatic push registration disabled.");
  }
}

// MARK: - Braze
- (void)changeUser:(CDVInvokedUrlCommand *)command {
  NSString *userId = [command argumentAtIndex:0 withDefault:nil];
  NSString *sdkAuthSignature = [command argumentAtIndex:1 withDefault:nil];
  if (userId && sdkAuthSignature) {
    [self.braze changeUser:userId sdkAuthSignature:sdkAuthSignature];
  } else if (userId) {
    [self.braze changeUser:userId];
  }
}

- (void)setSdkAuthenticationSignature:(CDVInvokedUrlCommand *)command {
  NSString *sdkAuthSignature = [command argumentAtIndex:0 withDefault:nil];
  if (sdkAuthSignature) {
    [self.braze setSDKAuthenticationSignature:sdkAuthSignature];
  }
}

- (void)subscribeToSdkAuthenticationFailures:(CDVInvokedUrlCommand *)command {
  self.sdkAuthCallbackID = command.callbackId;
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

// MARK: - Braze.User
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

- (void)setLastKnownLocation:(CDVInvokedUrlCommand *)command {
  NSNumber *latitude = [command argumentAtIndex:0 withDefault:nil];
  NSNumber *longitude = [command argumentAtIndex:1 withDefault:nil];
  NSNumber *altitude = [command argumentAtIndex:2 withDefault:nil];
  NSNumber *horizontalAccuracy = [command argumentAtIndex:3 withDefault:nil];
  NSNumber *verticalAccuracy = [command argumentAtIndex:4 withDefault:nil];

  if (!latitude || !longitude || !horizontalAccuracy) {
    NSLog(@"Invalid location information with the latitude: %@, longitude: %@, horizontalAccuracy: %@",
          latitude ? latitude : @"nil",
          longitude ? longitude : @"nil",
          horizontalAccuracy ? horizontalAccuracy : @"nil");
  } else if (!verticalAccuracy || !altitude) {
    [self.braze.user setLastKnownLocationWithLatitude:[latitude doubleValue]
                                             longitude:[longitude doubleValue]
                                    horizontalAccuracy:[horizontalAccuracy doubleValue]];
  } else {
    [self.braze.user setLastKnownLocationWithLatitude:[latitude doubleValue]
                                            longitude:[longitude doubleValue]
                                             altitude:[altitude doubleValue]
                                   horizontalAccuracy:[horizontalAccuracy doubleValue]
                                     verticalAccuracy:[verticalAccuracy doubleValue]];
  }
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
    for (id item in value) {
      if (![item isKindOfClass:[NSString class]]) {
        NSLog(@"Custom attribute array contains element that is not of type string. Aborting.");
        return;
      }
    }
    [self.braze.user setCustomAttributeArrayWithKey:key array:value];
  }
}

- (void)setCustomUserAttributeObjectArray:(CDVInvokedUrlCommand *)command {
  NSString *key = [command argumentAtIndex:0 withDefault:nil];
  id value = [command argumentAtIndex:1 withDefault:nil];
  if (key != nil && value != nil && [value isKindOfClass:[NSArray class]]) {
    for (id item in value) {
      if (![item isKindOfClass:[NSDictionary class]]) {
        NSLog(@"Custom attribute array contains element that is not of type object. Aborting.");
        return;
      }
    }
    [self.braze.user setNestedCustomAttributeArrayWithKey:key value:value];
  }
}

- (void)setCustomUserAttributeObject:(CDVInvokedUrlCommand *)command {
  NSString *key = [command argumentAtIndex:0 withDefault:nil];
  id value = [command argumentAtIndex:1 withDefault:nil];
  id merge = [command argumentAtIndex:2 withDefault:nil];

  if (key == nil || value == nil || ![value isKindOfClass:[NSDictionary class]]) {
    return;
  }

  if (!merge) {
    [self.braze.user setNestedCustomAttributeDictionaryWithKey:key value:value];
  } else if ([merge isKindOfClass:[NSNumber class]]) {
    BOOL mergeAsBool = [merge boolValue];
    [self.braze.user setNestedCustomAttributeDictionaryWithKey:key value:value merge:mergeAsBool];
  } else {
    NSLog(@"Invalid value received for `merge` parameter. Aborting.");
    return;
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
    [self.braze.user addToCustomAttributeStringArrayWithKey:key value:value];
  }
}

- (void)removeFromCustomAttributeArray:(CDVInvokedUrlCommand *)command {
  NSString *key = [command argumentAtIndex:0 withDefault:nil];
  NSString *value = [command argumentAtIndex:1 withDefault:nil];
  if (key != nil && value != nil) {
    [self.braze.user removeFromCustomAttributeStringArrayWithKey:key value:value];
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
  NSString *deviceId = self.braze.deviceId;
  [self sendCordovaSuccessPluginResultWithString:deviceId andCommand:command];
}

- (void)updateTrackingPropertyAllowList:(CDVInvokedUrlCommand *)command {
  NSDictionary* allowList = [command argumentAtIndex:0];
  NSArray<NSString *> *adding = allowList[@"adding"];
  NSArray<NSString *> *removing = allowList[@"removing"];
  NSArray<NSString *> *addingCustomEvents = allowList[@"addingCustomEvents"];
  NSArray<NSString *> *removingCustomEvents = allowList[@"removingCustomEvents"];
  NSArray<NSString *> *addingCustomAttributes = allowList[@"addingCustomAttributes"];
  NSArray<NSString *> *removingCustomAttributes = allowList[@"removingCustomAttributes"];

  NSMutableSet<BRZTrackingProperty *> *addingSet = [NSMutableSet set];
  NSMutableSet<BRZTrackingProperty *> *removingSet = [NSMutableSet set];

  for (NSString *propertyString in adding) {
    [addingSet addObject:[self convertTrackingProperty:(propertyString)]];
  }

  for (NSString *propertyString in removing) {
    [removingSet addObject:[self convertTrackingProperty:(propertyString)]];
  }

  // Parse custom strings
  if (addingCustomEvents.count > 0) {
    NSSet<NSString *> *customEvents = [NSSet setWithArray:addingCustomEvents];
    [addingSet addObject:[BRZTrackingProperty customEventWithEvents:customEvents]];
  }
  if (removingCustomEvents.count > 0) {
    NSSet<NSString *> *customEvents = [NSSet setWithArray:removingCustomEvents];
    [removingSet addObject:[BRZTrackingProperty customAttributeWithAttributes:customEvents]];
  }
  if (addingCustomAttributes.count > 0) {
    NSSet<NSString *> *customAttributes = [NSSet setWithArray:addingCustomAttributes];
    [addingSet addObject:[BRZTrackingProperty customAttributeWithAttributes:customAttributes]];
  }
  if (removingCustomAttributes.count > 0) {
    NSSet<NSString *> *customAttributes = [NSSet setWithArray:removingCustomAttributes];
    [removingSet addObject:[BRZTrackingProperty customAttributeWithAttributes:customAttributes]];
  }

  NSLog(@"Updating tracking allow list by adding: %@, removing %@", addingSet, removingSet);
  [self.braze updateTrackingAllowListAdding:addingSet removing:removingSet];
}

- (void)setAdTrackingEnabled:(CDVInvokedUrlCommand *)command {
  id argument = [command argumentAtIndex:0 withDefault:nil];
  
  if (argument == nil) {
    NSLog(@"Error: No argument provided for setAdTrackingEnabled.");
    return;
  }
  
  if (![argument isKindOfClass:[NSNumber class]]) {
    NSLog(@"Error: Expected argument to be a boolean value for setAdTrackingEnabled.");
    return;
  }
  
  BOOL adTrackingEnabled = [argument boolValue];
  
  if (adTrackingEnabled) {
    [self.braze setAdTrackingEnabled:YES];
    NSLog(@"Ad tracking enabled.");
  } else {
    [self.braze setAdTrackingEnabled:NO];
    NSLog(@"Ad tracking disabled.");
  }
}

// MARK: - BrazeUI
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

// MARK: - News Feed
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

// MARK: - Content Cards
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
    case BRZContentCardRawTypeImageOnly:
      formattedContentCardData[@"image"] = [card.image absoluteString];
      formattedContentCardData[@"imageAspectRatio"] = @(card.imageAspectRatio);
      formattedContentCardData[@"type"] = @"ImageOnly";
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

// MARK: - In-App Messages

/// Subscribes to in-app message updates.
- (void)subscribeToInAppMessage:(CDVInvokedUrlCommand *)command {
  bool useBrazeUI = [command argumentAtIndex:0 withDefault:nil];
  if (!useBrazeUI) {
    // A custom delegate is being used. Do nothing.
    return;
  }
  isInAppMessageSubscribed = YES;
}

/// Hides the currently displayed in-app message.
- (void)hideCurrentInAppMessage:(CDVInvokedUrlCommand *)command {
  [(BrazeInAppMessageUI *)self.braze.inAppMessagePresenter dismiss];
}

/// Logs an in-app message impression.
- (void)logInAppMessageImpression:(CDVInvokedUrlCommand *)command {
  NSString *inAppMessageString  = [command argumentAtIndex:0 withDefault:nil];
  NSLog(@"logInAppMessageImpression called with value %@", inAppMessageString);
  BRZInAppMessageRaw *inAppMessage = [self getInAppMessageFromString:inAppMessageString];
  if (inAppMessage) {
    [inAppMessage logImpressionUsing:self.braze];
  } else {
    NSLog(@"logInAppMessageImpression could not parse inAppMessage. Not logging impression.");
  }
}

/// Logs when an in-app message was clicked.
- (void)logInAppMessageClicked:(CDVInvokedUrlCommand *)command {
  NSString *inAppMessageString  = [command argumentAtIndex:0 withDefault:nil];
  NSLog(@"logInAppMessageClicked called with value %@", inAppMessageString);
  BRZInAppMessageRaw *inAppMessage = [self getInAppMessageFromString:inAppMessageString];
  if (inAppMessage) {
    [inAppMessage logClickWithButtonId:nil using:self.braze];
  } else {
    NSLog(@"logInAppMessageClicked could not parse inAppMessage. Not logging click.");
  }
}

/// Logs when an in-app message button was clicked.
- (void)logInAppMessageButtonClicked:(CDVInvokedUrlCommand *)command {
  NSString *inAppMessageString  = [command argumentAtIndex:0 withDefault:nil];
  NSNumber *button = [command argumentAtIndex:1 withDefault:0];
  NSLog(@"logInAppMessageButtonClicked called with value %@, button: %@", inAppMessageString, button);
  BRZInAppMessageRaw *inAppMessage = [self getInAppMessageFromString:inAppMessageString];
  double buttonId = [button doubleValue];
  if (inAppMessage) {
    [inAppMessage logClickWithButtonId:[@(buttonId) stringValue] using:self.braze];
  } else {
    NSLog(@"logInAppMessageButtonClicked could not parse inAppMessage. Not logging button click.");
  }
}

/// Process and perform in-app message click actions.
- (void)performInAppMessageAction:(CDVInvokedUrlCommand *)command {
  NSString *inAppMessageString  = [command argumentAtIndex:0 withDefault:nil];
  NSNumber *button = [command argumentAtIndex:1 withDefault:0];
  NSLog(@"performInAppMessageAction called with value %@, and button %@", inAppMessageString, button);
  BRZInAppMessageRaw *inAppMessage = [self getInAppMessageFromString:inAppMessageString];
  
  double buttonId = [button doubleValue];
  
  if (inAppMessage) {
    NSURL* url = nil;
    BOOL useWebView = NO;
    BRZInAppMessageRawClickAction clickAction = BRZInAppMessageRawClickActionURL;
      
    if (buttonId < 0) {
      url = inAppMessage.url;
      useWebView = inAppMessage.useWebView;
      clickAction = inAppMessage.clickAction;
    } else {
      for(int i = 0; i < inAppMessage.buttons.count; i++) {
        if (inAppMessage.buttons[i].identifier == buttonId) {
          url = inAppMessage.buttons[i].url;
          useWebView = inAppMessage.buttons[i].useWebView;
          clickAction = inAppMessage.buttons[i].clickAction;
        }
      }
    }
      
    NSLog(@"performInAppMessageAction trying %@", inAppMessage.url);
    inAppMessage.context = [[BRZInAppMessageContext alloc] initWithMessageRaw:inAppMessage using:self.braze];
    [inAppMessage.context processClickAction:clickAction url:url useWebView:useWebView];
  } else {
    NSLog(@"performInAppMessageAction could not parse inAppMessage. Not performing action.");
  }
}

/// Returns the in-app message for the JSON string. If the JSON fails decoding, returns nil.
- (BRZInAppMessageRaw *)getInAppMessageFromString:(NSString *)inAppMessageJSONString {
  NSData *inAppMessageData = [inAppMessageJSONString dataUsingEncoding:NSUTF8StringEncoding];
  BRZInAppMessageRaw *message = [BRZInAppMessageRaw decodingWithJson:inAppMessageData];
  return message;
}

// MARK: - Feature Flags
- (void)getFeatureFlag:(CDVInvokedUrlCommand *)command {
  NSString *featureFlagId = [command argumentAtIndex:0 withDefault:nil];
  BRZFeatureFlag *featureFlag = [self.braze.featureFlags featureFlagWithId:featureFlagId];
  if (featureFlag == nil) {
    [self sendCordovaSuccessPluginResultAsNull:command];
    return;
  }
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
  if (!featureFlag) {
    [self sendCordovaSuccessPluginResultAsNull:command];
    return;
  }

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
  if (!featureFlag) {
    [self sendCordovaSuccessPluginResultAsNull:command];
    return;
  }

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
  if (!featureFlag) {
    [self sendCordovaSuccessPluginResultAsNull:command];
    return;
  }

  NSNumber *numberProperty = [featureFlag numberPropertyForKey:propertyKey];
  if (numberProperty) {
    [self sendCordovaSuccessPluginResultWithDouble:[numberProperty doubleValue] andCommand:command];
  } else {
    [self sendCordovaSuccessPluginResultAsNull:command];
  }
}

- (void)logFeatureFlagImpression:(CDVInvokedUrlCommand *)command {
  NSString *featureFlagId = [command argumentAtIndex:0 withDefault:nil];
  if (featureFlagId) {
    [self.braze.featureFlags logFeatureFlagImpressionWithId:featureFlagId];
  } else {
    NSLog(@"No valid feature flag ID entered.");
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


// MARK: - BrazeSDKAuthDelegate
- (void)braze:(Braze * _Nonnull)braze sdkAuthenticationFailedWithError:(BRZSDKAuthenticationError * _Nonnull)error {
  if (self.sdkAuthCallbackID) {
    NSMutableDictionary *sdkAuthErrorEvent = [[NSMutableDictionary alloc] init];
    sdkAuthErrorEvent[@"signature"] = error.signature;
    sdkAuthErrorEvent[@"errorCode"] = @(error.code);
    sdkAuthErrorEvent[@"errorReason"] = error.reason;
    sdkAuthErrorEvent[@"userId"] = error.userId;
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                  messageAsDictionary:sdkAuthErrorEvent];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.sdkAuthCallbackID];
  }
}

// MARK: - Cordova Helper Methods
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

// MARK: - Helper Methods

/**
    Takes an NSString, trim whitespaces, and return the sanitized NSString converted to lowercase.
 **/
- (NSString *)sanitizeString:(NSString *)inputString {
  NSString *trimmedString = [inputString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  return ([trimmedString lowercaseString]);
}

- (BRZTrackingProperty *)convertTrackingProperty:(NSString *)propertyString {
  if ([propertyString isEqualToString:@"all_custom_attributes"]) {
    return BRZTrackingProperty.allCustomAttributes;
  } else if ([propertyString isEqualToString:@"all_custom_events"]) {
    return BRZTrackingProperty.allCustomEvents;
  } else if ([propertyString isEqualToString:@"analytics_events"]) {
    return BRZTrackingProperty.analyticsEvents;
  } else if ([propertyString isEqualToString:@"attribution_data"]) {
    return BRZTrackingProperty.attributionData;
  } else if ([propertyString isEqualToString:@"country"]) {
    return BRZTrackingProperty.country;
  } else if ([propertyString isEqualToString:@"dob"]) {
    return BRZTrackingProperty.dateOfBirth;
  } else if ([propertyString isEqualToString:@"device_data"]) {
    return BRZTrackingProperty.deviceData;
  } else if ([propertyString isEqualToString:@"email"]) {
    return BRZTrackingProperty.email;
  } else if ([propertyString isEqualToString:@"email_subscription_state"]) {
    return BRZTrackingProperty.emailSubscriptionState;
  } else if ([propertyString isEqualToString:@"everything"]) {
    return BRZTrackingProperty.everything;
  } else if ([propertyString isEqualToString:@"first_name"]) {
    return BRZTrackingProperty.firstName;
  } else if ([propertyString isEqualToString:@"gender"]) {
    return BRZTrackingProperty.gender;
  } else if ([propertyString isEqualToString:@"home_city"]) {
    return BRZTrackingProperty.homeCity;
  } else if ([propertyString isEqualToString:@"language"]) {
    return BRZTrackingProperty.language;
  } else if ([propertyString isEqualToString:@"last_name"]) {
    return BRZTrackingProperty.lastName;
  } else if ([propertyString isEqualToString:@"notification_subscription_state"]) {
    return BRZTrackingProperty.notificationSubscriptionState;
  } else if ([propertyString isEqualToString:@"phone_number"]) {
    return BRZTrackingProperty.phoneNumber;
  } else if ([propertyString isEqualToString:@"push_token"]) {
    return BRZTrackingProperty.pushToken;
  } else {
    NSLog(@"Invalid tracking property: %@", propertyString);
    return nil;
  }
}

// MARK: - BrazeInAppMessageUIDelegate

- (void)inAppMessage:(BrazeInAppMessageUI *)ui
          didPresent:(BRZInAppMessageRaw *)message
                  view:(UIView *)view {
  if (!isInAppMessageSubscribed) {
    return;
  }
  // Convert in-app message to string
  NSData *inAppMessageData = [message json];
  NSString *inAppMessageString = [[NSString alloc] initWithData:inAppMessageData encoding:NSUTF8StringEncoding];
  NSLog(@"In-app message received: %@", inAppMessageString);

  // Send in-app message string back to JavaScript in an `inAppMessageReceived` event
  NSString* jsStatement = [NSString stringWithFormat:@"app.inAppMessageReceived('%@');", inAppMessageString];
  [self.commandDelegate evalJs:jsStatement];
}

@end
