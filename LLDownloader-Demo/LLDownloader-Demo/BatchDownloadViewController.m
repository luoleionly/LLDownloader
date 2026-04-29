#import "BatchDownloadViewController.h"
#import "AppDelegate.h"

@implementation BatchDownloadViewController

- (void)viewDidLoad {
    self.sessionManager = [AppDelegate sharedDelegate].sessionManager3;
    [super viewDidLoad];
    self.title = @"批量下载";

    NSString *path = [[NSBundle mainBundle] pathForResource:@"VideoURLStrings" ofType:@"plist"];
    NSArray *arr = path ? [NSArray arrayWithContentsOfFile:path] : nil;
    self.URLStrings = arr ?: @[];

    [self setupManager];
    self.sessionManager.logger.option = LLLogOptionNone;
    [self updateUI];
    [self.tableView reloadData];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"批量下载"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(multiDownload)];
}

- (void)multiDownload {
    if (self.sessionManager.tasks.count >= self.URLStrings.count) return;
    __weak typeof(self) w = self;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        [w.sessionManager multiDownloadWithURLs:w.URLStrings
                                   headersArray:nil
                                      fileNames:nil
                                    onMainQueue:YES
                                        handler:^(LLSessionManager *_){
            [w updateUI];
            [w.tableView reloadData];
        }];
    });
}

@end
