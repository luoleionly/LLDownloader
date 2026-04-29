#import <UIKit/UIKit.h>
#import "LLDownloader.h"

NS_ASSUME_NONNULL_BEGIN

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong, nullable) UIWindow *window;

@property (nonatomic, strong, readonly) LLSessionManager *sessionManager1;
@property (nonatomic, strong, readonly) LLSessionManager *sessionManager2;
@property (nonatomic, strong, readonly) LLSessionManager *sessionManager3;
@property (nonatomic, strong, readonly) LLSessionManager *sessionManager4;

+ (instancetype)sharedDelegate;

@end

NS_ASSUME_NONNULL_END
