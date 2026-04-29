#import "DownloadViewController.h"
#import "AppDelegate.h"

@implementation DownloadViewController

- (void)viewDidLoad {
    self.sessionManager = [AppDelegate sharedDelegate].sessionManager4;
    [super viewDidLoad];
    self.title = @"下载管理";
    [self setupManager];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateUI];
    [self.tableView reloadData];
}

@end
