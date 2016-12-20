//
//  AppDelegate.m
//  YM
//
//  Created by user on 19/10/2015.
//  Copyright © 2015 Your Mixed. All rights reserved.
//

#import "AppDelegate.h"
#import "AppManager.h"
#import "Reachability.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h> //facebook
#import <FBSDKLoginKit/FBSDKLoginKit.h> //facebook
@import Firebase;
@import FirebaseInstanceID;
@import FirebaseMessaging;
//@import AirshipKit;

#import "TabBarController.h" //rb - test
#import "LoginViewController.h" //rb - test
#import "LoginRegisterViewController.h" //rb - test

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.

    // UINavigationBar appearance
    [[UINavigationBar appearance] setBarTintColor:UIColorFromRGB(0x323C4D)];
    [[UINavigationBar appearance] setTranslucent:NO];
    [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName]];
    
    // UITabBar appearance
    [[UITabBar appearance] setBarTintColor:[UIColor colorWithRed:(49.0/255.0) green:(59.0/255.0) blue:(77.0/255.0) alpha:1.0]];
    [[UITabBar appearance] setTranslucent:NO];

//    // UrbanAirship begin
//    //
//    // Populate AirshipConfig.plist with your app's info from https://go.urbanairship.com
//    // or set runtime properties here.
//    UAConfig *config = [UAConfig defaultConfig];
//    
//    // You can also programmatically override the plist values:
//    // config.developmentAppKey = @"YourKey";
//    // etc.
//    
//    // Call takeOff (which creates the UAirship singleton)
//    [UAirship takeOff:config];
//    //
//    // UrbanAirship end

    
    //facebook
    [[FBSDKApplicationDelegate sharedInstance] application:application
                             didFinishLaunchingWithOptions:launchOptions];
    
    // Firebase push notifications begin
    //
    // [START register_for_notifications]
    UIUserNotificationType allNotificationTypes =
    (UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge);
    UIUserNotificationSettings *settings =
    [UIUserNotificationSettings settingsForTypes:allNotificationTypes categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    [[UIApplication sharedApplication] registerForRemoteNotifications];
    // [END register_for_notifications]
    //
    // Firebase push notifications end
    
    // Use Firebase library to configure APIs
    [FIRApp configure];
    
    // Firebase push notifications
    //
    // Add observer for InstanceID token refresh callback.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tokenRefreshNotification:)
                                                 name:kFIRInstanceIDTokenRefreshNotification object:nil];
    
    // skip login if user did not logout
    [self skipLogin];
    
    return YES;
}

- (void)skipLogin
{
    NSDictionary *loginDetails = [[AppManager sharedAppManager] getLoginPlistData];
    NSString *email = [loginDetails valueForKey:@"email"];
    NSString *password = [loginDetails valueForKey:@"password"];
    
    // no login details exist or no internet connection - go to login/register screen
    if((!email.length && !password.length) || ![self isInternetConnection]) {
        return;
    }
    
    // login and jump to tabbar controller
    [[FIRAuth auth] signInWithEmail:email
                           password:password
                         completion:^(FIRUser *user, NSError *error) {
                             
                             if (error) {
                                 NSLog(@"%@", error.localizedDescription);
                             }
                             else {
                                 NSString *storyboardId = @"TabBarController";
                                 UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                                 UIViewController *initViewController = [storyboard instantiateViewControllerWithIdentifier:storyboardId];
                                 self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
                                 self.window.rootViewController = initViewController;
                                 [self.window makeKeyAndVisible];
                             }
                         }];
}

// Firebase push notifications begin
//
// [START receive_message]
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    // If you are receiving a notification message while your app is in the background,
    // this callback will not be fired till the user taps on the notification launching the application.
    // TODO: Handle data of notification
    
    // Print message ID.
    NSLog(@"Message ID: %@", userInfo[@"gcm.message_id"]);
    
    // Pring full message.
    NSLog(@"%@", userInfo);
}
// [END receive_message]

// [START refresh_token]
- (void)tokenRefreshNotification:(NSNotification *)notification {
    // Note that this callback will be fired everytime a new token is generated, including the first
    // time. So if you need to retrieve the token as soon as it is available this is where that
    // should be done.
    NSString *refreshedToken = [[FIRInstanceID instanceID] token];
    NSLog(@"InstanceID token: %@", refreshedToken);
    
    // Connect to FCM since connection may have failed when attempted before having a token.
    [self connectToFcm];
    
    // TODO: If necessary send token to application server.
}
// [END refresh_token]

// [START connect_to_fcm]
- (void)connectToFcm
{
    [[FIRMessaging messaging] connectWithCompletion:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"Unable to connect to FCM. %@", error);
        } else {
            NSLog(@"Connected to FCM.");
        }
    }];
}
// [END connect_to_fcm]

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [self connectToFcm];
    
    //facebook
    [FBSDKAppEvents activateApp];

}

// [START disconnect_from_fcm]
- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[FIRMessaging messaging] disconnect];
    NSLog(@"Disconnected from FCM");
}
// [END disconnect_from_fcm]

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    // for development
    [[FIRInstanceID instanceID] setAPNSToken:deviceToken type:FIRInstanceIDAPNSTokenTypeSandbox];
    
    // for production
    //     [[FIRInstanceID instanceID] setAPNSToken:deviceToken type:FIRInstanceIDAPNSTokenTypeProd];
}
//
// Firebase push notifications end

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    //rb - add later for facebook login
//    //facebook
//    return [[FBSDKApplicationDelegate sharedInstance] application:application
//                                                          openURL:url
//                                                sourceApplication:sourceApplication
//                                                       annotation:annotation];
    
    return YES;
}

#pragma mark - Internet Connection

- (BOOL)isInternetConnection
{
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus internetStatus = [reachability currentReachabilityStatus];
    
    if(internetStatus == NotReachable) {
        return NO;
    }
    
    return YES;
}

@end
