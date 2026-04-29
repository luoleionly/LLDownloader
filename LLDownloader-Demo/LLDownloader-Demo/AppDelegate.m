#import "AppDelegate.h"
#import "SingleDownloadViewController.h"
#import "MultipleDownloadViewController.h"
#import "BatchDownloadViewController.h"
#import "ListViewController.h"
#import "DownloadViewController.h"

@implementation AppDelegate

+ (instancetype)sharedDelegate {
    return (AppDelegate *)UIApplication.sharedApplication.delegate;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    LLSessionConfiguration *cfg1 = [[LLSessionConfiguration alloc] init];
    _sessionManager1 = [[LLSessionManager alloc] initWithIdentifier:@"ViewController1" configuration:cfg1];

    LLSessionConfiguration *cfg2 = [[LLSessionConfiguration alloc] init];
    cfg2.allowsCellularAccess = YES;
    NSString *path2 = [LLCache defaultDiskCachePathWithCacheName:@"Test"];
    LLCache *cache2 = [[LLCache alloc] initWithIdentifier:@"ViewController2"
                                               downloadPath:path2
                                            downloadTmpPath:nil
                                           downloadFilePath:nil];
    dispatch_queue_t q2 = dispatch_queue_create("com.LL.SessionManager.operationQueue", DISPATCH_QUEUE_SERIAL);
    _sessionManager2 = [[LLSessionManager alloc] initWithIdentifier:@"ViewController2"
                                                       configuration:cfg2
                                                              logger:nil
                                                               cache:cache2
                                                      operationQueue:q2];

    LLSessionConfiguration *cfg3 = [[LLSessionConfiguration alloc] init];
    _sessionManager3 = [[LLSessionManager alloc] initWithIdentifier:@"ViewController3" configuration:cfg3];

    LLSessionConfiguration *cfg4 = [[LLSessionConfiguration alloc] init];
    _sessionManager4 = [[LLSessionManager alloc] initWithIdentifier:@"ViewController4" configuration:cfg4];

    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.backgroundColor = UIColor.whiteColor;

    UITabBarController *tab = [[UITabBarController alloc] init];

    UINavigationController *n1 = [[UINavigationController alloc] initWithRootViewController:[[SingleDownloadViewController alloc] init]];
    n1.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"单任务" image:nil tag:0];

    UINavigationController *n2 = [[UINavigationController alloc] initWithRootViewController:[[MultipleDownloadViewController alloc] init]];
    n2.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"多任务" image:nil tag:1];

    UINavigationController *n3 = [[UINavigationController alloc] initWithRootViewController:[[BatchDownloadViewController alloc] init]];
    n3.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"批量" image:nil tag:2];

    ListViewController *list = [[ListViewController alloc] init];
    UINavigationController *n4 = [[UINavigationController alloc] initWithRootViewController:list];
    n4.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"列表" image:nil tag:3];

    tab.viewControllers = @[n1, n2, n3, n4];
    tab.tabBar.tintColor = UIColor.systemBlueColor;
    if (@available(iOS 15.0, *)) {
        UITabBarAppearance *a = [[UITabBarAppearance alloc] init];
        [a configureWithOpaqueBackground];
        tab.tabBar.standardAppearance = a;
        tab.tabBar.scrollEdgeAppearance = a;
    }

    self.window.rootViewController = tab;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)application:(UIApplication *)application
handleEventsForBackgroundURLSession:(NSString *)identifier
  completionHandler:(void (^)(void))completionHandler {
    for (LLSessionManager *m in @[_sessionManager1, _sessionManager2, _sessionManager3, _sessionManager4]) {
        if ([m.identifier isEqualToString:identifier]) {
            m.completionHandler = completionHandler;
            break;
        }
    }
}

@end
