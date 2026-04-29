//
//  LLProtected.m
//  LLDownloader
//

#import "LLProtected.h"
#import <os/lock.h>

@implementation LLUnfairLock {
    os_unfair_lock _lock;
}

- (instancetype)init {
    if ((self = [super init])) {
        _lock = OS_UNFAIR_LOCK_INIT;
    }
    return self;
}

- (void)around:(NS_NOESCAPE dispatch_block_t)block {
    os_unfair_lock_lock(&_lock);
    block();
    os_unfair_lock_unlock(&_lock);
}

- (id)aroundReturning:(NS_NOESCAPE id _Nullable (^)(void))block {
    os_unfair_lock_lock(&_lock);
    id result = block();
    os_unfair_lock_unlock(&_lock);
    return result;
}

@end

#pragma mark - Debouncer

@implementation LLDebouncer {
    dispatch_queue_t _queue;
    NSTimeInterval _interval;
    dispatch_block_t _workItem; // cancellable
}

- (instancetype)initWithTimeInterval:(NSTimeInterval)timeInterval {
    if ((self = [super init])) {
        _interval = timeInterval;
        _queue = dispatch_queue_create([[NSString stringWithFormat:@"com.LL.Debouncer.%@", [NSUUID UUID].UUIDString] UTF8String],
                                       DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)executeOnQueue:(dispatch_queue_t)queue work:(dispatch_block_t)work {
    dispatch_sync(_queue, ^{
        if (self->_workItem) {
            dispatch_block_cancel(self->_workItem);
        }
        __weak typeof(self) weakSelf = self;
        __weak dispatch_queue_t weakQueue = queue;
        dispatch_block_t item = dispatch_block_create(0, ^{
            dispatch_queue_t q = weakQueue;
            if (q) dispatch_async(q, ^{ work(); });
            __strong typeof(weakSelf) strong = weakSelf;
            if (strong) strong->_workItem = nil;
        });
        self->_workItem = item;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self->_interval * NSEC_PER_SEC)),
                       self->_queue, item);
    });
}

@end

#pragma mark - Throttler

@implementation LLThrottler {
    dispatch_queue_t _queue;
    NSTimeInterval _interval;
    dispatch_block_t _workItem;
    BOOL _latest;
}

- (instancetype)initWithTimeInterval:(NSTimeInterval)timeInterval latest:(BOOL)latest {
    if ((self = [super init])) {
        _interval = timeInterval;
        _latest = latest;
        _queue = dispatch_queue_create([[NSString stringWithFormat:@"com.LL.Throttler.%@", [NSUUID UUID].UUIDString] UTF8String],
                                       DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)executeOnQueue:(dispatch_queue_t)queue work:(dispatch_block_t)work {
    dispatch_sync(_queue, ^{
        if (self->_workItem != nil && !self->_latest) return;

        __weak typeof(self) weakSelf = self;
        __weak dispatch_queue_t weakQueue = queue;
        dispatch_block_t item = dispatch_block_create(0, ^{
            dispatch_queue_t q = weakQueue;
            if (q) dispatch_async(q, ^{ work(); });
            __strong typeof(weakSelf) strong = weakSelf;
            if (strong) strong->_workItem = nil;
        });

        if (self->_workItem == nil) {
            self->_workItem = item;
            __weak typeof(self) w = self;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self->_interval * NSEC_PER_SEC)),
                           self->_queue, ^{
                __strong typeof(w) strong = w;
                dispatch_block_t cur = strong ? strong->_workItem : nil;
                if (cur) cur();
            });
        } else {
            self->_workItem = item;
        }
    });
}

@end
