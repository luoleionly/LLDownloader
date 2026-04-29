//
//  LLExecuter.h
//  LLDownloader
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Executes a handler on main queue (if `onMainQueue` is YES) or on the caller's queue.
/// The generic Swift `Executer<T>` is represented here as a concrete object that takes an `id`.
@interface LLExecuter<__covariant ObjectType> : NSObject

@property (nonatomic, readonly) BOOL onMainQueue;

- (instancetype)initWithOnMainQueue:(BOOL)onMainQueue handler:(void (^ _Nullable)(ObjectType object))handler NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (void)execute:(ObjectType)object;

@end

/// Runs block on main queue. If already on main, invokes directly (sync).
FOUNDATION_EXPORT void LLExecuteOnMain(dispatch_block_t block);

NS_ASSUME_NONNULL_END
