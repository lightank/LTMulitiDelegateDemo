//
//  AppFirstDelegate.m
//  LTMulitiDelegateDemo
//
//  Created by huanyu.li on 2019/11/1.
//  Copyright © 2019 huanyu.li. All rights reserved.
//

#import "AppFirstDelegate.h"
#import <UIKit/UIKit.h>

@implementation AppFirstDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    NSLog(@"名称：%@\n", NSStringFromClass(self.class));
    return YES;
}

@end
