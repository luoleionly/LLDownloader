//
//  LLExecuter.m
//  LLDownloader
//

#import "LLExecuter.h"

void LLExecuteOnMain(dispatch_block_t block) {
    if (!block) return;
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

@implementation LLExecuter {
    void (^_handler)(id);
}

- (instancetype)initWithOnMainQueue:(BOOL)onMainQueue handler:(void (^)(id))handler {
    if ((self = [super init])) {
        _onMainQueue = onMainQueue;
        _handler = [handler copy];
    }
    return self;
}

- (void)execute:(id)object {
    if (!_handler) return;
    if (_onMainQueue) {
        void (^h)(id) = _handler;
        LLExecuteOnMain(^{ h(object); });
    } else {
        _handler(object);
    }
}

@end
