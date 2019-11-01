//
//  main.m
//  LTMulitiDelegateDemo
//
//  Created by huanyu.li on 2019/11/1.
//  Copyright © 2019 huanyu.li. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "LTMulitiDelegate.h"
#import "AppFirstDelegate.h"
#import "AppSecondDelegate.h"
#import "AppThirdDelegate.h"
#import "AppFourthDelegate.h"

int main(int argc, char * argv[]) {
    NSString * appDelegateClassName;
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        LTMulitiDelegate *mulitiDelegate = [[LTMulitiDelegate alloc] init];
        AppFourthDelegate *fourthDelegate = [AppFourthDelegate new];
        [mulitiDelegate addStrongDelegate:[AppThirdDelegate new] priority:0];
        [mulitiDelegate addStrongDelegate:[AppSecondDelegate new] priority:3];
        [mulitiDelegate addStrongDelegate:[AppDelegate new] priority:5];
        [mulitiDelegate addStrongDelegate:fourthDelegate priority:7];
        [mulitiDelegate addStrongDelegate:[AppFirstDelegate new] priority:4];
        [mulitiDelegate addStrongDelegate:[AppFourthDelegate new] priority:-4];
        [mulitiDelegate removeDelegate:fourthDelegate];
        appDelegateClassName = NSStringFromClass([LTMulitiDelegate class]);
    }
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}
