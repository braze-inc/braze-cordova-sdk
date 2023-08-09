#import "AppDelegate+Braze.h"
#import "BrazePlugin.h"
#import <objc/runtime.h>

@import BrazeKit;
@import UserNotifications;

static NSString *const PluginName = @"BrazePlugin";

@implementation AppDelegate (BrazeNotifications)
+ (void)swizzleHostAppDelegate {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      Class class = [self class];
      id delegate = [UIApplication sharedApplication].delegate;

      if ([delegate respondsToSelector:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:)]) {
        SEL registerForNotificationSelector = @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:);
        SEL swizzledRegisterForNotificationSelector = @selector(braze_swizzled_application:didRegisterForRemoteNotificationsWithDeviceToken:);
        [self swizzleMethodWithClass:class originalSelector:registerForNotificationSelector andSwizzledSelector:swizzledRegisterForNotificationSelector];
      } else {
        SEL noregisterForNotificationSelector = @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:);
        SEL swizzledNoregisterForNotificationSelector = @selector(braze_swizzled_no_application:didRegisterForRemoteNotificationsWithDeviceToken:);
        [self swizzleMethodWithClass:class originalSelector:noregisterForNotificationSelector andSwizzledSelector:swizzledNoregisterForNotificationSelector];
      }

      if ([delegate respondsToSelector:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)]) {
        SEL receivedNotificationSelector = @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:);
        SEL swizzledReceivedNotificationSelector = @selector(braze_swizzled_application:didReceiveRemoteNotification:fetchCompletionHandler:);
        [self swizzleMethodWithClass:class originalSelector:receivedNotificationSelector andSwizzledSelector:swizzledReceivedNotificationSelector];
      } else {
        SEL noReceivedNotificationSelector = @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:);
        SEL swizzledNoReceivedNotificationSelector = @selector(braze_swizzled_no_application:didReceiveRemoteNotification:fetchCompletionHandler:);
        [self swizzleMethodWithClass:class originalSelector:noReceivedNotificationSelector andSwizzledSelector:swizzledNoReceivedNotificationSelector];
      }

      if ([delegate respondsToSelector:@selector(application:didReceiveRemoteNotification:)]) {
        SEL receivedNotificationSelector = @selector(application:didReceiveRemoteNotification:);
        SEL swizzledReceivedNotificationSelector = @selector(braze_swizzled_application:didReceiveRemoteNotification:);
        [self swizzleMethodWithClass:class originalSelector:receivedNotificationSelector andSwizzledSelector:swizzledReceivedNotificationSelector];
      } else {
        SEL noReceivedNotificationSelector = @selector(application:didReceiveRemoteNotification:);
        SEL swizzledNoReceivedNotificationSelector = @selector(braze_swizzled_no_application:didReceiveRemoteNotification:);
        [self swizzleMethodWithClass:class originalSelector:noReceivedNotificationSelector andSwizzledSelector:swizzledNoReceivedNotificationSelector];
      }

      if ([delegate respondsToSelector:@selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)]) {
        SEL receivedNotificationResponseSelector = @selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:);
        SEL swizzledReceivedNotificationResponseSelector = @selector(braze_swizzled_userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:);
        [self swizzleMethodWithClass:class originalSelector:receivedNotificationResponseSelector andSwizzledSelector:swizzledReceivedNotificationResponseSelector];
      } else {
        SEL noReceivedNotificationResponseSelector = @selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:);
        SEL swizzledNoReceivedNotificationResponseSelector = @selector(braze_swizzled_no_userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:);
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

- (void)braze_swizzled_application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [self braze_swizzled_application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    BrazePlugin *pluginInstance = [self.viewController getCommandInstance:PluginName];
    [pluginInstance.braze.notifications registerDeviceToken:deviceToken];
}

- (void)braze_swizzled_no_application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
  // If the delegate is not implemented, swizzle the method but don't call the original (or we'd get in a loop)
  BrazePlugin *pluginInstance = [self.viewController getCommandInstance:PluginName];
  [pluginInstance.braze.notifications registerDeviceToken:deviceToken];
}

- (void)braze_swizzled_application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
  if ([[UIApplication sharedApplication].delegate respondsToSelector:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)]) {
    [self braze_swizzled_application:application
         didReceiveRemoteNotification:userInfo
               fetchCompletionHandler:completionHandler];
  }
  // We pass a nil completion handler to the SDK since the host delegate might be calling the completion handler instead
  BrazePlugin *pluginInstance = [self.viewController getCommandInstance:PluginName];
  (void)[pluginInstance.braze.notifications handleBackgroundNotificationWithUserInfo:userInfo
                                                              fetchCompletionHandler:^(UIBackgroundFetchResult result) {}];
}

- (void)braze_swizzled_no_application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
  // If neither delegate is implemented, swizzle the method but don't call the original (or we'd get in a loop)
  BrazePlugin *pluginInstance = [self.viewController getCommandInstance:PluginName];
  (void)[pluginInstance.braze.notifications handleBackgroundNotificationWithUserInfo:userInfo
                                                              fetchCompletionHandler:completionHandler];
}

- (void)braze_swizzled_application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
  [self braze_swizzled_application:application didReceiveRemoteNotification:userInfo];
  BrazePlugin *pluginInstance = [self.viewController getCommandInstance:PluginName];
  (void)[pluginInstance.braze.notifications handleBackgroundNotificationWithUserInfo:userInfo
                                                              fetchCompletionHandler:^(UIBackgroundFetchResult result) {}];
}

- (void)braze_swizzled_no_application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
  BrazePlugin *pluginInstance = [self.viewController getCommandInstance:PluginName];
  (void)[pluginInstance.braze.notifications handleBackgroundNotificationWithUserInfo:userInfo
                                                              fetchCompletionHandler:^(UIBackgroundFetchResult result) {}];
}

- (void)braze_swizzled_userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
  [self braze_swizzled_userNotificationCenter:center didReceiveNotificationResponse:response withCompletionHandler:completionHandler];
  // We pass a nil completion handler to the SDK since the host delegate might be calling the completion handler instead
  BrazePlugin *pluginInstance = [self.viewController getCommandInstance:PluginName];
  (void)[pluginInstance.braze.notifications handleUserNotificationWithResponse:response
                                                         withCompletionHandler:^{}];
}

- (void)braze_swizzled_no_userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
  BrazePlugin *pluginInstance = [self.viewController getCommandInstance:PluginName];
  (void)[pluginInstance.braze.notifications handleUserNotificationWithResponse:response
                                                         withCompletionHandler:completionHandler];
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    BrazePlugin *pluginInstance = [self.viewController getCommandInstance:PluginName];
    NSString *enableForegroundNotifications = pluginInstance.commandDelegate.settings[@"com.braze.display_foreground_push_notifications"];
    if ([enableForegroundNotifications isEqualToString:@"YES"]) {
        completionHandler(UNNotificationPresentationOptionAlert);
    }
}
@end
