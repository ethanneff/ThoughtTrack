//
//  AppDelegate.m
//  ThoughtTrack
//
//  Created by Ethan Neff on 1/11/15.
//  Copyright (c) 2015 ethanneff. All rights reserved.
//

#import "AppDelegate.h"
#import "MasterViewController.h"
#import "Config.h"
#import <ENSDK/Advanced/ENSDKAdvanced.h>

@implementation AppDelegate

// load
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[Config sharedInstance] setIsAppLoaded:YES];
    
    // launch screen time
    sleep(0.75f);
    
    // evernote
//    NSString *SANDBOX_HOST = ENSessionHostSandbox;
    NSString *CONSUMER_KEY = @"ethanneff-7635";
    NSString *CONSUMER_SECRET = @"575cc9d7eea8d853";
    
    [ENSession setSharedSessionConsumerKey:CONSUMER_KEY
                            consumerSecret:CONSUMER_SECRET
                              optionalHost:nil];
    
    // window
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.rootViewController = [[MasterViewController alloc] init];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [[Config sharedInstance] setIsAppLoaded:NO];
}


// active (phone call interruption)
- (void)applicationDidBecomeActive:(UIApplication *)application {
    [[Config sharedInstance] setIsAppActive:YES];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [[Config sharedInstance] setIsAppActive:NO];
}


// open
- (void)applicationWillEnterForeground:(UIApplication *)application {
    [[Config sharedInstance] setIsAppOpen:YES];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [[Config sharedInstance] setIsAppOpen:NO];
}

// evernote handling
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    BOOL didHandle = [[ENSession sharedSession] handleOpenURL:url];
    
    return didHandle;
}

@end
