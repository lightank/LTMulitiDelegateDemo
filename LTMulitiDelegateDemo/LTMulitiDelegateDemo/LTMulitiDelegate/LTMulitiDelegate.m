//
//  LTMulitiDelegate.m
//  LTMulitiDelegateDemo
//
//  Created by huanyu.li on 2019/11/1.
//  Copyright © 2019 huanyu.li. All rights reserved.
//

#import "LTMulitiDelegate.h"

@interface LTMulitiDelegate ()
{
    CFRunLoopObserverRef _observer;
}

/// 信号量
@property(nonatomic, strong) dispatch_semaphore_t semaphore;

@property(nonatomic, assign) NSUInteger normalIndex;

/// 代理属性描述
@property(nonatomic, strong) NSMutableArray<NSString *> *indentifiers;
/// 代理容器
@property(nonatomic, strong) NSMutableArray *delegates;

@property(nonatomic, strong) NSMutableArray *asyncBlocks;

@end

@implementation LTMulitiDelegate

- (instancetype)init
{
    return self;
}

- (void)dealloc
{
    if (_observer)
    {
        CFRunLoopRemoveObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);
        CFRelease(_observer);
    }
}

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static LTMulitiDelegate *instance = nil;
    dispatch_once(&onceToken,^{
        instance = [[super alloc] init];
        instance.semaphore = dispatch_semaphore_create(1);
        instance.indentifiers = [NSMutableArray array];
        instance.delegates = [NSMutableArray array];
        instance.asyncBlocks = [NSMutableArray array];
        instance.normalIndex = 0;
        [instance addRunLoopObserver];
    });
    return instance;
}

+ (id)alloc{
    return [self sharedInstance];
}

/**
 添加代理，并弱引用这个delegate
 */
- (void)addWeakDelegate:(id)delegate priority:(NSInteger)priority
{
    [self _addDelegate:delegate priority:priority weakReference:YES];
}

/**
 添加代理，并强引用这个delegate
 */
- (void)addStrongDelegate:(id)delegate priority:(NSInteger)priority
{
    [self _addDelegate:delegate priority:priority weakReference:NO];
}

- (void)_addDelegate:(id)delegate priority:(NSInteger)priority weakReference:(BOOL)weakReference
{
    if (!delegate) return;
    NSString *indentifier = [self indentifierForPriority:priority weakReference:weakReference];
    NSUInteger index = -1;
    BOOL havePlace = NO;
    if ([self.indentifiers containsObject:indentifier]) // 有找到indentifier，只需要加入到对应的delegate容器
    {
        index = [self.indentifiers indexOfObject:indentifier];
        if (index >= self.delegates.count)
        {
            return;
        }
        
        // 这里无需区分是否强弱引用，因为NSHashTable/NSMutableSet 都有addObject方法
        NSHashTable *container = self.delegates[index];
        BOOL currentType = weakReference ? [container isKindOfClass:[NSHashTable class]] : [container isKindOfClass:[NSMutableSet class]];
        if (!currentType) return;
        [container addObject:delegate];
        havePlace = YES;
    }
    else    // 没找到indentifier,必须找到需要插入的位置，并新增delegate容器
    {
        // 先新增容器
        // 这里无需区分是否强弱引用，因为NSHashTable/NSMutableSet 都有addObject方法
        NSHashTable *container = weakReference ? [NSHashTable weakObjectsHashTable] : ((NSHashTable *)([NSMutableSet set]));
        [container addObject:delegate];
        
        // 找到合适的位置
        if (self.indentifiers.count == 0)   // 没有delegate容器，则直接插入
        {
            // 将新增容器插入到合适位置
            [self.indentifiers addObject:indentifier];
            [self.delegates addObject:container];
        }
        else // 已经有delegate容器，找到合适位置插入
        {
            if (priority < 0)   // 延后调用的东西
            {
                for (NSInteger i = self.normalIndex; i < self.indentifiers.count; i++)
                {
                    NSString *currentIndentifier = self.indentifiers[i];
                    NSInteger currentPriority = currentIndentifier.integerValue;
                    if (priority >= currentPriority)
                    {
                        index = i;
                        havePlace = YES;
                        break;
                    }
                }
            }
            else    // 正常调用的东西
            {
                NSUInteger endIndex = (self.normalIndex <= 0) ? (self.indentifiers.count - 1) : self.normalIndex;
                for (NSInteger i = 0; i <= endIndex; i++)
                {
                    NSString *currentIndentifier = self.indentifiers[i];
                    NSInteger currentPriority = currentIndentifier.integerValue;
                    if (priority > currentPriority)
                    {
                        index = i;
                        havePlace = YES;
                        break;
                    }
                }
            }
            
            // 将新增容器插入到合适位置
            if (index == -1)    // 找不到位置
            {
                [self.indentifiers addObject:indentifier];
                [self.delegates addObject:container];
            }
            else    // 找到位置
            {
                [self.indentifiers insertObject:indentifier atIndex:index];
                [self.delegates insertObject:container atIndex:index];
            }
        }
    }
    
    if (havePlace && priority == 0)
    {
        self.normalIndex = index;
    }
}

- (void)removeDelegate:(id)delegate
{
    if (!delegate) return;
    NSMutableArray *nullContainerIndexs = [NSMutableArray array];
    for (int i = 0; i < self.delegates.count; i++)
    {
        NSHashTable *container = self.delegates[i];
        [container removeObject:delegate];
        if (container.count == 0)
        {
            [nullContainerIndexs addObject:@(i)];
        }
    }
    
    for (NSNumber *index in nullContainerIndexs)
    {
        [self.delegates removeObjectAtIndex:index.intValue];
        [self.indentifiers removeObjectAtIndex:index.intValue];
    }
    self.normalIndex = 0;
}

- (NSString *)indentifierForPriority:(NSInteger)priority weakReference:(BOOL)weakReference
{
    NSString *referenceIndentifier = weakReference ? @"_w" : @"_s";
    NSString *indentifier = [@(priority).stringValue stringByAppendingString:referenceIndentifier];
    return indentifier;
}

- (BOOL)isProxy
{
    return YES;
}

#pragma mark - 消息转发部分
- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector
{
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    NSMethodSignature *methodSignature = nil;
    for (NSHashTable *container in self.delegates)
    {
        for (id delegate in container.objectEnumerator)
        {
            methodSignature = [delegate methodSignatureForSelector:selector];
            break;
        }
    }
    dispatch_semaphore_signal(_semaphore);
    
    // 未找到方法时，返回默认方法 "- (void)method"，防止崩溃
    methodSignature = methodSignature ? : [NSObject instanceMethodSignatureForSelector:@selector(description)];
    return methodSignature;
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    // 为了避免造成递归死锁，copy一份delegates而不是直接用信号量将for循环包裹
    NSMutableArray *delegates = [self.delegates copy];
    NSMutableArray *indentifiers = [self.indentifiers copy];
    dispatch_semaphore_signal(_semaphore);
    
    SEL selector = invocation.selector;
    for (int i = 0; i < delegates.count; i++)
    {
        NSHashTable *container = delegates[i];
        NSInteger priority = ((NSString *)(indentifiers[i])).integerValue;
        if (priority >= 0)  // 正常调用
        {
            for (id delegate in container.objectEnumerator)
            {
                if ([delegate respondsToSelector:selector])
                {
                    // 拷贝一个Invocation，以免意外修改target导致crash
                    NSInvocation *dupInvocation = [self copyInvocation:invocation];
                    [dupInvocation invokeWithTarget:delegate];
                    void *null = NULL;
                    [dupInvocation setReturnValue:&null];
                }
            }
        }
        else    // 延后调用
        {
            for (id delegate in container.objectEnumerator)
            {
                if ([delegate respondsToSelector:selector])
                {
                    // 拷贝一个Invocation，以免意外修改target导致crash
                    NSInvocation *dupInvocation = [self copyInvocation:invocation];
                    dupInvocation.target = delegate;
                    void(^block)(void) = ^(void){
                        [dupInvocation invokeWithTarget:delegate];
                    };
                    [self.asyncBlocks addObject:block];
                }
            }
        }
    }

    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    dispatch_semaphore_signal(_semaphore);
}

- (NSInvocation *)copyInvocation:(NSInvocation *)invocation
{
    SEL selector = invocation.selector;
    NSMethodSignature *methodSignature = invocation.methodSignature;
    NSInvocation *copyInvocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    copyInvocation.selector = selector;
    
    NSUInteger count = methodSignature.numberOfArguments;
    for (NSUInteger i = 2; i < count; i++)
    {
        void *value;
        [invocation getArgument:&value atIndex:i];
        [copyInvocation setArgument:&value atIndex:i];
    }
    [copyInvocation retainArguments];
    return copyInvocation;
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    BOOL respondsToSelector = NO;
    NSMutableArray *delegates = [self.delegates copy];
    for (int i = 0; i < delegates.count; i++)
    {
        NSHashTable *container = delegates[i];
        for (id delegate in container.objectEnumerator)
        {
            if ([delegate respondsToSelector:aSelector])
            {
                return YES;
            }
        }
    }

    return respondsToSelector;
}

#pragma mark - 监听runloop
- (void)addRunLoopObserver
{
    __weak typeof(self) weakself = self;
    _observer = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, kCFRunLoopBeforeWaiting, YES, 0, ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
        if (activity != kCFRunLoopBeforeWaiting) {
            return;
        }

        __strong typeof(weakself) strongself = weakself;
        BOOL showHomePage = NO;
        if (showHomePage) {
            return;
        }
        if (strongself.asyncBlocks.count == 0) {
            return;
        }
        for (void(^block)(void) in strongself.asyncBlocks) {
            !block ?: block();
        }
        [strongself.asyncBlocks removeAllObjects];
    });

    CFRunLoopAddObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);
}


@end

/** returnValue在64位系统下的值：
 v ==> void
 c ==> char
 C ==> unsigned char
 * ==> char *
 B ==> BOOL
 i ==> int
 I ==> unsigned int
 s ==> short
 S ==> unsigned short
 q ==> long/long long/NSInteger
 Q ==> unsigned long/unsigned long long/NSUInteger
 f ==> float
 d ==> double / CGFloat
 @ ==> id
 @? ==> block
 # ==> Class
 : ==> SEL
 **/

// 参考：https://github.com/gzhongcheng/GZCMulitiDelegate
