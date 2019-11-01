//
//  AppDelegate.m
//  LTMulitiDelegateDemo
//
//  Created by huanyu.li on 2019/11/1.
//  Copyright © 2019 huanyu.li. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    ViewController *vc = [[ViewController alloc] init];
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = UIColor.whiteColor;
    self.window.rootViewController = vc;
    [self.window makeKeyAndVisible];
    NSLog(@"名称：%@\n", NSStringFromClass(self.class));
    return YES;
}

@end
