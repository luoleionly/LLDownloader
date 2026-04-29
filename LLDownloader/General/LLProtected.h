//
//  LLProtected.h
//  LLDownloader
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// os_unfair_lock wrapper with a scoped `around:` helper.
@interface LLUnfairLock : NSObject
- (void)around:(NS_NOESCAPE dispatch_block_t)block;
- (nullable id)aroundReturning:(NS_NOESCAPE id _Nullable (^)(void))block;
@end

/// Debouncer: every `execute:` call cancels the previously scheduled one.
@interface LLDebouncer : NSObject
- (instancetype)initWithTimeInterval:(NSTimeInterval)timeInterval;
- (void)executeOnQueue:(dispatch_queue_t)queue work:(dispatch_block_t)work;
@end

/// Throttler: swallows calls that arrive while another is scheduled.
/// If `latest` is YES, the most recent work replaces the pending one.
@interface LLThrottler : NSObject
- (instancetype)initWithTimeInterval:(NSTimeInterval)timeInterval latest:(BOOL)latest;
- (void)executeOnQueue:(dispatch_queue_t)queue work:(dispatch_block_t)work;
@end

NS_ASSUME_NONNULL_END
