//
//  LLSessionConfiguration.m
//  LLDownloader
//

#import "LLSessionConfiguration.h"

static const NSInteger kMaxConcurrentTasksLimit = 6;

@implementation LLSessionConfiguration {
    NSInteger _maxConcurrentTasksLimit;
}

- (instancetype)init {
    if ((self = [super init])) {
        _timeoutIntervalForRequest = 60.0;
        _maxConcurrentTasksLimit = kMaxConcurrentTasksLimit;
        _allowsExpensiveNetworkAccess = YES;
        _allowsConstrainedNetworkAccess = YES;
        _allowsCellularAccess = NO;
    }
    return self;
}

- (NSInteger)maxConcurrentTasksLimit { return _maxConcurrentTasksLimit; }

- (void)setMaxConcurrentTasksLimit:(NSInteger)value {
    NSInteger v = MIN(value, kMaxConcurrentTasksLimit);
    _maxConcurrentTasksLimit = MAX(v, 1);
}

- (id)copyWithZone:(NSZone *)zone {
    LLSessionConfiguration *c = [[[self class] allocWithZone:zone] init];
    c.timeoutIntervalForRequest = self.timeoutIntervalForRequest;
    c.maxConcurrentTasksLimit = self.maxConcurrentTasksLimit;
    c.allowsExpensiveNetworkAccess = self.allowsExpensiveNetworkAccess;
    c.allowsConstrainedNetworkAccess = self.allowsConstrainedNetworkAccess;
    c.allowsCellularAccess = self.allowsCellularAccess;
    return c;
}

@end
