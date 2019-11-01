//
//  LTMulitiDelegate.h
//  LTMulitiDelegateDemo
//
//  Created by huanyu.li on 2019/11/1.
//  Copyright © 2019 huanyu.li. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LTMulitiDelegate : NSProxy


- (instancetype)init;

/**
 添加代理，并弱引用这个delegate
 @param delegate delegate
 @param priority 如果 priority >0 则正常直接调用，如果 priority <0 则在退出当前runloop循环时调用，且值越大越被先调用
 */
- (void)addWeakDelegate:(id)delegate priority:(NSInteger)priority;

/**
 添加代理，并强引用这个delegate
 @param delegate delegate
 @param priority 如果 priority >0 则正常直接调用，如果 priority <0 则在退出当前runloop循环时调用，且值越大越被先调用
 */
- (void)addStrongDelegate:(id)delegate priority:(NSInteger)priority;

/**
 删除代理
 @param delegate delegate
 */
- (void)removeDelegate:(id)delegate;

@end

NS_ASSUME_NONNULL_END
