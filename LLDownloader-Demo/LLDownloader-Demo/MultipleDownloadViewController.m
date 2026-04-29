#import "MultipleDownloadViewController.h"
#import "AppDelegate.h"

@implementation MultipleDownloadViewController

- (void)viewDidLoad {
    self.sessionManager = [AppDelegate sharedDelegate].sessionManager2;
    [super viewDidLoad];
    self.title = @"多任务下载";
    self.URLStrings = @[
        @"https://officecdn-microsoft-com.akamaized.net/pr/C1297A47-86C4-4C1F-97FA-950631F94777/MacAutoupdate/Microsoft_Office_16.24.19041401_Installer.pkg",
        @"http://dldir1.qq.com/qqfile/QQforMac/QQ_V6.5.2.dmg",
        @"http://issuecdn.baidupcs.com/issue/netdisk/MACguanjia/BaiduNetdisk_mac_2.2.3.dmg",
        @"http://m4.pc6.com/cjh3/VicomsoftFTPClient.dmg",
        @"https://qd.myapp.com/myapp/qqteam/pcqq/QQ9.0.8_2.exe",
        @"http://gxiami.alicdn.com/xiami-desktop/update/XiamiMac-03051058.dmg",
        @"http://dldir1.qq.com/qqfile/QQforMac/QQ_V4.2.4.dmg"
    ];
    [self setupManager];
    [self updateUI];
    [self.tableView reloadData];

    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addDownloadTask)];
    UIBarButtonItem *trash = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(deleteDownloadTask)];
    self.navigationItem.leftBarButtonItems = @[add, trash];
}

- (void)addDownloadTask {
    NSMutableArray *downloading = [NSMutableArray array];
    for (LLDownloadTask *t in self.sessionManager.tasks) [downloading addObject:t.url.absoluteString];
    NSString *url = nil;
    for (NSString *s in self.URLStrings) if (![downloading containsObject:s]) { url = s; break; }
    if (!url) return;

    __weak typeof(self) w = self;
    [self.sessionManager downloadWithURL:url headers:nil fileName:nil onMainQueue:YES handler:^(LLDownloadTask *_){
        NSInteger index = w.sessionManager.tasks.count - 1;
        [w.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        [w updateUI];
    }];
}

- (void)deleteDownloadTask {
    NSUInteger n = self.sessionManager.tasks.count;
    if (n == 0) return;
    NSInteger index = n - 1;
    LLDownloadTask *task = [self.sessionManager.tasks ll_safeObjectAtIndex:index];
    if (!task) return;
    __weak typeof(self) w = self;
    [self.sessionManager removeTask:task completely:NO onMainQueue:YES handler:^(LLDownloadTask *_){
        [w.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        [w updateUI];
    }];
}

@end
