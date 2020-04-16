#import <Foundation/Foundation.h>
#import <Appboy_iOS_SDK/ABKIDFADelegate.h>

@interface IDFADelegate : NSObject <ABKIDFADelegate>

- (NSString *)advertisingIdentifierString;
- (BOOL)isAdvertisingTrackingEnabled;

@end
