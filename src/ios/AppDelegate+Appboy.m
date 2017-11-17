#import "AppDelegate+Appboy.h"
#import <objc/runtime.h>
#import "AppboyKit.h" 

@implementation AppDelegate (appboyNotifications)
+ (void)swizzleHostAppDelegate {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      Class class = [self class];
      id delegate = [UIApplication sharedApplication].delegate;

      if ([delegate respondsToSelector:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:)]) {
        SEL registerForNotificationSelector = @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:);
        SEL swizzledRegisterForNotificationSelector = @selector(appboy_swizzled_application:didRegisterForRemoteNotificationsWithDeviceToken:);
        [self swizzleMethodWithClass:class originalSelector:registerForNotificationSelector andSwizzledSelector:swizzledRegisterForNotificationSelector];
      } else {
        SEL noregisterForNotificationSelector = @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:);
        SEL swizzledNoregisterForNotificationSelector = @selector(appboy_swizzled_no_application:didRegisterForRemoteNotificationsWithDeviceToken:);
        [self swizzleMethodWithClass:class originalSelector:noregisterForNotificationSelector andSwizzledSelector:swizzledNoregisterForNotificationSelector];
      }
      
      if ([delegate respondsToSelector:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)]) {
        SEL receivedNotificationSelector = @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:);
        SEL swizzledReceivedNotificationSelector = @selector(appboy_swizzled_application:didReceiveRemoteNotification:fetchCompletionHandler:);
        [self swizzleMethodWithClass:class originalSelector:receivedNotificationSelector andSwizzledSelector:swizzledReceivedNotificationSelector];
      } else {
        SEL noReceivedNotificationSelector = @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:);
        SEL swizzledNoReceivedNotificationSelector = @selector(appboy_swizzled_no_application:didReceiveRemoteNotification:fetchCompletionHandler:);
        [self swizzleMethodWithClass:class originalSelector:noReceivedNotificationSelector andSwizzledSelector:swizzledNoReceivedNotificationSelector];
      }

      if ([delegate respondsToSelector:@selector(application:didReceiveRemoteNotification:)]) {
        SEL receivedNotificationSelector = @selector(application:didReceiveRemoteNotification:);
        SEL swizzledReceivedNotificationSelector = @selector(appboy_swizzled_application:didReceiveRemoteNotification:);
        [self swizzleMethodWithClass:class originalSelector:receivedNotificationSelector andSwizzledSelector:swizzledReceivedNotificationSelector];
      } else {
        SEL noReceivedNotificationSelector = @selector(application:didReceiveRemoteNotification:);
        SEL swizzledNoReceivedNotificationSelector = @selector(appboy_swizzled_no_application:didReceiveRemoteNotification:);
        [self swizzleMethodWithClass:class originalSelector:noReceivedNotificationSelector andSwizzledSelector:swizzledNoReceivedNotificationSelector];
      }
      
      if ([delegate respondsToSelector:@selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)]) {
        SEL receivedNotificationResponseSelector = @selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:);
        SEL swizzledReceivedNotificationResponseSelector = @selector(appboy_swizzled_userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:);
        [self swizzleMethodWithClass:class originalSelector:receivedNotificationResponseSelector andSwizzledSelector:swizzledReceivedNotificationResponseSelector];
      } else {
        SEL noReceivedNotificationResponseSelector = @selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:);
        SEL swizzledNoReceivedNotificationResponseSelector = @selector(appboy_swizzled_no_userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:);
        [self swizzleMethodWithClass:class originalSelector:noReceivedNotificationResponseSelector andSwizzledSelector:swizzledNoReceivedNotificationResponseSelector];
      }
    });
}

+ (void)swizzleMethodWithClass:(Class)class originalSelector:(SEL)originalSelector andSwizzledSelector:(SEL)swizzledSelector {
  Method originalMethod = class_getInstanceMethod(class, originalSelector);
  Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
  
  BOOL didAddMethod =
  class_addMethod(class,
                  originalSelector,
                  method_getImplementation(swizzledMethod),
                  method_getTypeEncoding(swizzledMethod));
  
  if (didAddMethod) {
    class_replaceMethod(class,
                        swizzledSelector,
                        method_getImplementation(originalMethod),
                        method_getTypeEncoding(originalMethod));
  } else {
    method_exchangeImplementations(originalMethod, swizzledMethod);
  }
}

- (void)appboy_swizzled_application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [self appboy_swizzled_application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    [[Appboy sharedInstance] registerPushToken:
               [NSString stringWithFormat:@"%@", deviceToken]];
}

- (void)appboy_swizzled_no_application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
  // If the delegate is not implemented, swizzle the method but don't call the original (or we'd get in a loop)
  [[Appboy sharedInstance] registerPushToken:
   [NSString stringWithFormat:@"%@", deviceToken]];
}

- (void)appboy_swizzled_application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
  if ([[UIApplication sharedApplication].delegate respondsToSelector:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)]) {
    [self appboy_swizzled_application:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
  }
  // We pass a nil completion handler to the SDK since the host delegate might be calling the completion handler instead
  [[Appboy sharedInstance] registerApplication:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:nil];
}

- (void)appboy_swizzled_no_application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
  // If neither delegate is implemented, swizzle the method but don't call the original (or we'd get in a loop)
  [[Appboy sharedInstance] registerApplication:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
}

- (void)appboy_swizzled_application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
  [self appboy_swizzled_application:application didReceiveRemoteNotification:userInfo];
  [[Appboy sharedInstance] registerApplication:application didReceiveRemoteNotification:userInfo];
}

- (void)appboy_swizzled_no_application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
  [[Appboy sharedInstance] registerApplication:application didReceiveRemoteNotification:userInfo];
}

- (void)appboy_swizzled_userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)())completionHandler {
  [self appboy_swizzled_userNotificationCenter:center didReceiveNotificationResponse:response withCompletionHandler:completionHandler];
  // We pass a nil completion handler to the SDK since the host delegate might be calling the completion handler instead
  [[Appboy sharedInstance] userNotificationCenter:center didReceiveNotificationResponse:response withCompletionHandler:nil];
}

- (void)appboy_swizzled_no_userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)())completionHandler {
  [[Appboy sharedInstance] userNotificationCenter:center didReceiveNotificationResponse:response withCompletionHandler:completionHandler];
}
@end
