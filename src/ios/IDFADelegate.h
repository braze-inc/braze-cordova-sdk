#import <Foundation/Foundation.h>
#if __has_include(<Appboy_iOS_SDK/ABKIDFADelegate.h>)
#import <Appboy_iOS_SDK/ABKIDFADelegate.h>
#elif __has_include(<Appboy-iOS-SDK/Appboy_iOS_SDK.framework/Headers/ABKIDFADelegate.h>)
#import <Appboy-iOS-SDK/Appboy_iOS_SDK.framework/Headers/ABKIDFADelegate.h>
#else
#import "ABKIDFADelegate.h"
#endif

@interface IDFADelegate : NSObject <ABKIDFADelegate>

@end
