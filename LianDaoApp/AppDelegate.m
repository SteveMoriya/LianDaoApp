//
//  AppDelegate.m
//  smartLianYun
//
//  Created by Steve on 03/08/2017.
//  Copyright © 2017 jianbuwang. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "JPUSHService.h"
#import <UserNotifications/UserNotifications.h>

@interface AppDelegate ()<JPUSHRegisterDelegate>

@property (nonatomic, strong) ViewController *rootViewController;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    self.rootViewController = [[ViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:self.rootViewController];
    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
    
    self.reachability = [Reachability reachabilityWithHostname:@"http://www.baidu.com"];
    
    [self registerAPNS:launchOptions];
    
    [[UIApplication sharedApplication]setApplicationIconBadgeNumber:0];
    [application cancelAllLocalNotifications];
    [JPUSHService resetBadge];
    
//    //注册
//    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
//    [defaultCenter addObserver:self selector:@selector(networkDidReceiveMessage:) name:kJPFNetworkDidLoginNotification object:nil];
    
    NSString * userIDString = [[NSUserDefaults standardUserDefaults] objectForKey:@"userid"];
    
    if (userIDString == nil) {
        
    } else if (![userIDString isEqualToString:@"null"] ) {
        
        [JPUSHService setAlias:userIDString completion:^(NSInteger iResCode, NSString *iAlias, NSInteger seq) {
        } seq:0];
    }
    
    return YES;
}

////通知方法
//- (void)networkDidLoginMessage:(NSNotification *)notification {
//
//    //调用接口
//
//    //注销通知
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:kJPFNetworkDidLoginNotification object:nil];
//}


- (void)registerAPNS:(NSDictionary *)launchOptions
{
    if (IOS10) {
        
        JPUSHRegisterEntity * entity = [[JPUSHRegisterEntity alloc] init];
        if (@available(iOS 10.0, *)) {
            entity.types = UNAuthorizationOptionAlert|UNAuthorizationOptionBadge|UNAuthorizationOptionSound;
        } else {
            // Fallback on earlier versions
        }
        [JPUSHService registerForRemoteNotificationConfig:entity delegate:self];
    }
    else if (IOS8_10) {
        
        [JPUSHService registerForRemoteNotificationTypes:(UIUserNotificationTypeBadge |
                                                          UIUserNotificationTypeSound |
                                                          UIUserNotificationTypeAlert)
                                              categories:nil];
    }
    else {
        
        [JPUSHService registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                                          UIRemoteNotificationTypeSound |
                                                          UIRemoteNotificationTypeAlert)
                                              categories:nil];
        
    }
    
#ifdef DEBUG
    [JPUSHService setupWithOption:launchOptions appKey:@"b02c07ea20527c3336370fac" channel:@"JPush" apsForProduction:NO advertisingIdentifier:nil];
#else
    [JPUSHService setupWithOption:launchOptions appKey:@"b02c07ea20527c3336370fac" channel:@"appStore" apsForProduction:YES advertisingIdentifier:nil];
#endif
    
}

#pragma mark-- 处理推送
- (void)handleRemoteNotification:(NSDictionary *)launchOptions
{
    //判断是否点击了apns才导致启动app
    NSDictionary *remoteNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (remoteNotification) {
        
        YJLog(@"__%@",remoteNotification);
        [self remoteNotificationWithUserInfo:remoteNotification];
    }
}

- (void)application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    
    YJLog(@"注册APNs成功并上报DeviceToken");
    [JPUSHService registerDeviceToken:deviceToken];
    
    NSLog(@"____%@",[JPUSHService registrationID]);
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    
    YJLog(@"did Fail To Register For Remote Notifications With Error: %@", error);
}

- (void)jpushNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(NSInteger))completionHandler  API_AVAILABLE(ios(10.0)){
    
    NSDictionary * userInfo = notification.request.content.userInfo;
    if (@available(iOS 10.0, *)) {
        if([notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
            [JPUSHService handleRemoteNotification:userInfo];
        }
    } else {
        // Fallback on earlier versions
    }
    if (@available(iOS 10.0, *)) {
        completionHandler(UNNotificationPresentationOptionAlert);
    } else {
        // Fallback on earlier versions
    } // 需要执行这个方法，选择是否提醒用户，有Badge、Sound、Alert三种类型可以选择设置
}

- (void)jpushNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)())completionHandler {
    
    NSDictionary * userInfo = response.notification.request.content.userInfo;
    if (@available(iOS 10.0, *)) {
        if([response.notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
            [JPUSHService handleRemoteNotification:userInfo];
        }
    } else {
        // Fallback on earlier versions
    }
    completionHandler();
    
    //iOS10 处理远程推送消息
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateInactive) {
        
        NSDictionary *userInfo = response.notification.request.content.userInfo;
        [self remoteNotificationWithUserInfo:userInfo];
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    
    [JPUSHService handleRemoteNotification:userInfo];
    
    //    [[UIApplication sharedApplication]setApplicationIconBadgeNumber:0];
    //    [application cancelAllLocalNotifications];
    //    [JPUSHService resetBadge];
    
    completionHandler(UIBackgroundFetchResultNewData);
    
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateInactive) {
        
        [self remoteNotificationWithUserInfo:userInfo];
    }
}

#pragma mark-- 处理推送过来的链接
- (void)remoteNotificationWithUserInfo:(NSDictionary *)userInfo{
    
    if (userInfo) {
        NSString *urlString = [[userInfo objectForKey:@"extras"] objectForKey: @"linkUrl"];
        if (urlString) {
            
            NSString *userid = [[NSUserDefaults standardUserDefaults] objectForKey:@"userid"];
            urlString = [NSString stringWithFormat:@"%@&visitType=1&userid=%@",urlString,userid];
            [self.rootViewController loadWebView:urlString];
        }
    }
    
}

//网页直接跳转app支持,添加微信支付回调
- (BOOL) application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
//    if ([[NSString stringWithFormat:@"%@",url] rangeOfString:[NSString stringWithFormat:@"%@://pay",WX_APPID]].location != NSNotFound) {
//        return  [WXApi handleOpenURL:url delegate:self];
//    }
    
    if (!url) {
        return NO;
    } else  {
        return YES;
    }
    return YES;
    
}

- (BOOL) application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    ////????
    
//    if ([[NSString stringWithFormat:@"%@",url] rangeOfString:[NSString stringWithFormat:@"%@://pay",WX_APPID]].location != NSNotFound) {
//        return  [WXApi handleOpenURL:url delegate:self];
//    }
    
    
    if (!url) {
        return NO;
    } else  {
        
        NSString* urlString = [url absoluteString];
        [self.rootViewController loadWebView:urlString];
        
        return YES;
    }
    
}



- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    
        [[UIApplication sharedApplication]setApplicationIconBadgeNumber:0];
//        [application cancelAllLocalNotifications];
        [JPUSHService resetBadge];
    
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
