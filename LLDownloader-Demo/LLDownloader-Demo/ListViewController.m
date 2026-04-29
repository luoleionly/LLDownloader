#import "ListViewController.h"
#import "AppDelegate.h"
#import "DownloadViewController.h"
#import "LLDownloader.h"

static NSString *const kCellID = @"ListViewCell";

@interface ListViewController ()
@property (nonatomic, copy) NSArray<NSString *> *URLStrings;
@end

@implementation ListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"可下载文件";
    self.URLStrings = @[
        @"https://officecdn-microsoft-com.akamaized.net/pr/C1297A47-86C4-4C1F-97FA-950631F94777/MacAutoupdate/Microsoft_Office_16.24.19041401_Installer.pkg",
        @"http://dldir1.qq.com/qqfile/QQforMac/QQ_V6.5.2.dmg",
        @"http://issuecdn.baidupcs.com/issue/netdisk/MACguanjia/BaiduNetdisk_mac_2.2.3.dmg",
        @"http://m4.pc6.com/cjh3/VicomsoftFTPClient.dmg",
        @"https://qd.myapp.com/myapp/qqteam/pcqq/QQ9.0.8_2.exe",
        @"http://api.gfs100.cn/upload/20180126/201801261545095005.mp4",
        @"http://dldir1.qq.com/qqfile/QQforMac/QQ_V4.2.4.dmg",
    ];
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:kCellID];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"下载管理"
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(openDownloadVC)];
}

- (void)openDownloadVC {
    [self.navigationController pushViewController:[[DownloadViewController alloc] init] animated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return self.URLStrings.count; }

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellID forIndexPath:indexPath];
    NSString *name = [NSString stringWithFormat:@"文件%ld.mp4", (long)(indexPath.row + 1)];
    cell.textLabel.text = name;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *url = self.URLStrings[indexPath.row];
    NSString *fileName = [NSString stringWithFormat:@"文件%ld.mp4", (long)(indexPath.row + 1)];
    [[AppDelegate sharedDelegate].sessionManager4 downloadWithURL:url
                                                          headers:nil
                                                         fileName:fileName
                                                      onMainQueue:YES
                                                          handler:nil];
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"已加入下载"
                                                               message:fileName
                                                        preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

@end
