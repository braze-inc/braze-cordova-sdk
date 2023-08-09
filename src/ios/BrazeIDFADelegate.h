@protocol BrazeIDFADelegate <NSObject>

/**
 * String representation of the identifier for advertiser.
 *
 * This value will be pushed up to Braze's platforms as the iOS IDFA.
 */
- (NSString *)advertisingIdentifierString;

/**
 * Determines if SDK should enable advertiser tracking.
 */
- (BOOL)isAdvertisingTrackingEnabledOrATTAuthorized;

@end
