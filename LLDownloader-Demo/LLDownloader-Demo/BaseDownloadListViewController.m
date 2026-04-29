#import "BaseDownloadListViewController.h"
#import "DownloadTaskCell.h"

@interface BaseDownloadListViewController () {
    UITableView *_tableView;
    UILabel *_totalTasksLabel;
    UILabel *_totalSpeedLabel;
    UILabel *_timeRemainingLabel;
    UILabel *_totalProgressLabel;
    UISwitch *_taskLimitSwitch;
    UISwitch *_cellularAccessSwitch;
}
@end

@implementation BaseDownloadListViewController

- (UITableView *)tableView { return _tableView; }
- (UILabel *)totalTasksLabel { return _totalTasksLabel; }
- (UILabel *)totalSpeedLabel { return _totalSpeedLabel; }
- (UILabel *)timeRemainingLabel { return _timeRemainingLabel; }
- (UILabel *)totalProgressLabel { return _totalProgressLabel; }
- (UISwitch *)taskLimitSwitch { return _taskLimitSwitch; }
- (UISwitch *)cellularAccessSwitch { return _cellularAccessSwitch; }

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    [self buildUI];

    int64_t freeMB = [NSFileManager defaultManager].ll_freeDiskSpaceInBytes / 1024 / 1024;
    NSLog(@"手机剩余储存空间为： %lldMB", freeMB);

    self.sessionManager.logger.option = LLLogOptionDefault;
    [self updateSwitches];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"编辑"
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(toggleEditing)];
}

- (UILabel *)makeStat:(NSString *)text {
    UILabel *l = [[UILabel alloc] init];
    l.font = [UIFont systemFontOfSize:12];
    l.text = text;
    l.textColor = UIColor.secondaryLabelColor;
    return l;
}

- (UIButton *)makeButton:(NSString *)title action:(SEL)sel {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    [b setTitle:title forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont systemFontOfSize:13];
    [b addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    b.layer.cornerRadius = 6;
    b.layer.borderWidth = 1;
    b.layer.borderColor = UIColor.systemBlueColor.CGColor;
    return b;
}

- (void)buildUI {
    _totalTasksLabel = [self makeStat:@"总任务：0/0"];
    _totalSpeedLabel = [self makeStat:@"总速度：0B/s"];
    _timeRemainingLabel = [self makeStat:@"剩余时间：--"];
    _totalProgressLabel = [self makeStat:@"总进度：0"];

    UIStackView *statsRow = [[UIStackView alloc] initWithArrangedSubviews:@[_totalTasksLabel, _totalSpeedLabel, _timeRemainingLabel, _totalProgressLabel]];
    statsRow.axis = UILayoutConstraintAxisHorizontal;
    statsRow.distribution = UIStackViewDistributionFillEqually;
    statsRow.spacing = 4;

    UIButton *startAll = [self makeButton:@"全部开始" action:@selector(totalStart)];
    UIButton *suspendAll = [self makeButton:@"全部暂停" action:@selector(totalSuspend)];
    UIButton *cancelAll = [self makeButton:@"全部取消" action:@selector(totalCancel)];
    UIButton *deleteAll = [self makeButton:@"全部删除" action:@selector(totalDelete)];

    UIStackView *btnRow = [[UIStackView alloc] initWithArrangedSubviews:@[startAll, suspendAll, cancelAll, deleteAll]];
    btnRow.axis = UILayoutConstraintAxisHorizontal;
    btnRow.distribution = UIStackViewDistributionFillEqually;
    btnRow.spacing = 6;

    _taskLimitSwitch = [[UISwitch alloc] init];
    [_taskLimitSwitch addTarget:self action:@selector(taskLimitChanged:) forControlEvents:UIControlEventValueChanged];
    UILabel *tl = [self makeStat:@"限制并发"];

    _cellularAccessSwitch = [[UISwitch alloc] init];
    [_cellularAccessSwitch addTarget:self action:@selector(cellularChanged:) forControlEvents:UIControlEventValueChanged];
    UILabel *cl = [self makeStat:@"蜂窝网络"];

    UIStackView *switchRow = [[UIStackView alloc] initWithArrangedSubviews:@[tl, _taskLimitSwitch, cl, _cellularAccessSwitch]];
    switchRow.axis = UILayoutConstraintAxisHorizontal;
    switchRow.spacing = 8;
    switchRow.alignment = UIStackViewAlignmentCenter;

    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.tableFooterView = [[UIView alloc] init];
    _tableView.rowHeight = 164;
    [_tableView registerClass:DownloadTaskCell.class forCellReuseIdentifier:DownloadTaskCell.reuseIdentifier];

    UIStackView *root = [[UIStackView alloc] initWithArrangedSubviews:@[statsRow, btnRow, switchRow, _tableView]];
    root.axis = UILayoutConstraintAxisVertical;
    root.spacing = 8;
    root.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:root];

    UILayoutGuide *g = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [root.topAnchor constraintEqualToAnchor:g.topAnchor constant:8],
        [root.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:12],
        [root.trailingAnchor constraintEqualToAnchor:g.trailingAnchor constant:-12],
        [root.bottomAnchor constraintEqualToAnchor:g.bottomAnchor],
        [btnRow.heightAnchor constraintEqualToConstant:36],
    ]];
}

- (void)toggleEditing {
    [_tableView setEditing:!_tableView.editing animated:YES];
    self.navigationItem.rightBarButtonItem.title = _tableView.editing ? @"完成" : @"编辑";
}

- (void)updateSwitches {
    _taskLimitSwitch.on = self.sessionManager.configuration.maxConcurrentTasksLimit < 3;
    _cellularAccessSwitch.on = self.sessionManager.configuration.allowsCellularAccess;
}

- (void)updateUI {
    _totalTasksLabel.text = [NSString stringWithFormat:@"%lu/%lu",
                             (unsigned long)self.sessionManager.succeededTasks.count,
                             (unsigned long)self.sessionManager.tasks.count];
    _totalSpeedLabel.text = self.sessionManager.speedString;
    _timeRemainingLabel.text = self.sessionManager.timeRemainingString;
    _totalProgressLabel.text = [NSString stringWithFormat:@"%.2f",
                                self.sessionManager.progress.fractionCompleted];
}

- (void)setupManager {
    __weak typeof(self) w = self;
    [[self.sessionManager onProgress:YES handler:^(LLSessionManager *m) { [w updateUI]; }]
                       onCompletion:YES handler:^(LLSessionManager *m) { [w updateUI]; }];
}

// Total actions
- (void)totalStart    { __weak typeof(self) w = self; [self.sessionManager totalStartOnMainQueue:YES handler:^(LLSessionManager *_){ [w.tableView reloadData]; }]; }
- (void)totalSuspend  { __weak typeof(self) w = self; [self.sessionManager totalSuspendOnMainQueue:YES handler:^(LLSessionManager *_){ [w.tableView reloadData]; }]; }
- (void)totalCancel   { __weak typeof(self) w = self; [self.sessionManager totalCancelOnMainQueue:YES handler:^(LLSessionManager *_){ [w.tableView reloadData]; }]; }
- (void)totalDelete   { __weak typeof(self) w = self; [self.sessionManager totalRemoveCompletely:NO onMainQueue:YES handler:^(LLSessionManager *_){ [w.tableView reloadData]; }]; }

- (void)taskLimitChanged:(UISwitch *)s {
    LLSessionConfiguration *c = self.sessionManager.configuration;
    c.maxConcurrentTasksLimit = s.on ? 2 : 6;
    self.sessionManager.configuration = c;
}
- (void)cellularChanged:(UISwitch *)s {
    LLSessionConfiguration *c = self.sessionManager.configuration;
    c.allowsCellularAccess = s.on;
    self.sessionManager.configuration = c;
}

#pragma mark - table view

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.sessionManager.tasks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [tableView dequeueReusableCellWithIdentifier:DownloadTaskCell.reuseIdentifier forIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    LLDownloadTask *task = [self.sessionManager.tasks ll_safeObjectAtIndex:indexPath.row];
    if (!task || ![cell isKindOfClass:DownloadTaskCell.class]) return;
    DownloadTaskCell *c = (DownloadTaskCell *)cell;

    // detach old callbacks
    if (c.task) {
        [c.task onProgress:YES handler:^(id t) {}];
        [c.task onSuccess:YES handler:^(id t) {}];
        [c.task onFailure:YES handler:^(id t) {}];
    }
    c.task = task;
    c.titleLabel.text = task.fileName;
    [c updateProgress:task];

    __weak typeof(self) ws = self;
    __weak DownloadTaskCell *wc = c;
    c.tapBlock = ^(DownloadTaskCell *cell) {
        LLDownloadTask *t = [ws.sessionManager.tasks ll_safeObjectAtIndex:indexPath.row];
        if (!t) return;
        if ([t.status isEqualToString:LLStatusWaiting] || [t.status isEqualToString:LLStatusRunning]) {
            [ws.sessionManager suspendTask:t onMainQueue:YES handler:nil];
        } else if ([t.status isEqualToString:LLStatusSuspended] || [t.status isEqualToString:LLStatusFailed]) {
            [ws.sessionManager startTask:t onMainQueue:YES handler:nil];
        }
    };

    [[[task onProgress:YES handler:^(id t) { [wc updateProgress:t]; }]
              onSuccess:YES handler:^(id t) { [wc updateProgress:t]; }]
              onFailure:YES handler:^(id t) { [wc updateProgress:t]; }];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath { return YES; }

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)style forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (style != UITableViewCellEditingStyleDelete) return;
    LLDownloadTask *task = [self.sessionManager.tasks ll_safeObjectAtIndex:indexPath.row];
    if (!task) return;
    __weak typeof(self) w = self;
    [self.sessionManager removeTask:task completely:NO onMainQueue:YES handler:^(LLDownloadTask *_){
        [w.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [w updateUI];
    }];
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    [self.sessionManager moveTaskFromIndex:sourceIndexPath.row toIndex:destinationIndexPath.row];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
