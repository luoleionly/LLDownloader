#import "SingleDownloadViewController.h"
#import "AppDelegate.h"
#import "LLDownloader.h"

static NSString *const kURLString = @"http://dldir1.qq.com/qqfile/QQforMac/QQ_V4.2.4.dmg";
static NSString *const kMD5 = @"9e2a3650530b563da297c9246acaad5c";

@interface SingleDownloadViewController ()
@property (nonatomic, strong) UILabel *progressLabel;
@property (nonatomic, strong) UILabel *speedLabel;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UILabel *timeRemainingLabel;
@property (nonatomic, strong) UILabel *startDateLabel;
@property (nonatomic, strong) UILabel *endDateLabel;
@property (nonatomic, strong) UILabel *validationLabel;
@property (nonatomic, strong, readonly) LLSessionManager *sessionManager;
@end

@implementation SingleDownloadViewController

- (LLSessionManager *)sessionManager { return [AppDelegate sharedDelegate].sessionManager1; }

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"单任务下载";
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    [self buildUI];

    LLDownloadTask *existing = [self.sessionManager.tasks firstObject];
    if (existing) {
        __weak typeof(self) w = self;
        [[[existing onProgress:YES handler:^(id task) { [w updateUI:task]; }]
                   onCompletion:YES handler:^(id task) { [w updateUI:task]; }]
         validateFileWithCode:kMD5 type:LLVerificationTypeMD5 onMainQueue:YES
                      handler:^(LLDownloadTask *task) { [w updateUI:task]; }];
    }
}

- (UIButton *)buttonWithTitle:(NSString *)title action:(SEL)sel color:(UIColor *)color {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    [b setTitle:title forState:UIControlStateNormal];
    b.backgroundColor = color;
    [b setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    b.layer.cornerRadius = 8;
    b.translatesAutoresizingMaskIntoConstraints = NO;
    [b addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    return b;
}

- (UILabel *)makeInfoLabel:(NSString *)text {
    UILabel *l = [[UILabel alloc] init];
    l.font = [UIFont systemFontOfSize:14];
    l.text = text;
    l.translatesAutoresizingMaskIntoConstraints = NO;
    return l;
}

- (void)buildUI {
    _progressLabel = [self makeInfoLabel:@"progress： 0.00%"];
    _speedLabel = [self makeInfoLabel:@"speed： 0B/s"];
    _timeRemainingLabel = [self makeInfoLabel:@"剩余时间： --"];
    _startDateLabel = [self makeInfoLabel:@"开始时间： --"];
    _endDateLabel = [self makeInfoLabel:@"结束时间： --"];
    _validationLabel = [self makeInfoLabel:@"文件验证： 未知"];
    _validationLabel.textColor = UIColor.systemBlueColor;

    _progressView = [[UIProgressView alloc] init];
    _progressView.translatesAutoresizingMaskIntoConstraints = NO;

    UIButton *startB = [self buttonWithTitle:@"开始" action:@selector(start) color:UIColor.systemBlueColor];
    UIButton *suspendB = [self buttonWithTitle:@"暂停" action:@selector(suspend) color:UIColor.systemOrangeColor];
    UIButton *cancelB = [self buttonWithTitle:@"取消" action:@selector(cancelTask) color:UIColor.systemGrayColor];
    UIButton *deleteB = [self buttonWithTitle:@"删除" action:@selector(deleteTask) color:UIColor.systemRedColor];
    UIButton *clearB = [self buttonWithTitle:@"清理磁盘" action:@selector(clearDisk) color:UIColor.systemPurpleColor];

    UIStackView *btnRow = [[UIStackView alloc] initWithArrangedSubviews:@[startB, suspendB, cancelB, deleteB]];
    btnRow.axis = UILayoutConstraintAxisHorizontal;
    btnRow.distribution = UIStackViewDistributionFillEqually;
    btnRow.spacing = 8;
    btnRow.translatesAutoresizingMaskIntoConstraints = NO;

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[
        _progressLabel, _progressView, _speedLabel, _timeRemainingLabel,
        _startDateLabel, _endDateLabel, _validationLabel,
        btnRow, clearB
    ]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 12;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:stack];

    UILayoutGuide *g = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:g.topAnchor constant:16],
        [stack.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:16],
        [stack.trailingAnchor constraintEqualToAnchor:g.trailingAnchor constant:-16],
        [btnRow.heightAnchor constraintEqualToConstant:44],
        [clearB.heightAnchor constraintEqualToConstant:44],
    ]];
}

- (void)updateUI:(LLDownloadTask *)task {
    double per = task.progress.fractionCompleted;
    self.progressLabel.text = [NSString stringWithFormat:@"progress： %.2f%%", per * 100];
    self.progressView.observedProgress = task.progress;
    self.speedLabel.text = [NSString stringWithFormat:@"speed： %@", task.speedString];
    self.timeRemainingLabel.text = [NSString stringWithFormat:@"剩余时间： %@", task.timeRemainingString];
    self.startDateLabel.text = [NSString stringWithFormat:@"开始时间： %@", task.startDateString];
    self.endDateLabel.text = [NSString stringWithFormat:@"结束时间： %@", task.endDateString];
    NSString *v;
    switch (task.validation) {
        case LLValidationUnknown: v = @"未知"; self.validationLabel.textColor = UIColor.systemBlueColor; break;
        case LLValidationCorrect: v = @"正确"; self.validationLabel.textColor = UIColor.systemGreenColor; break;
        case LLValidationIncorrect: v = @"错误"; self.validationLabel.textColor = UIColor.systemRedColor; break;
    }
    self.validationLabel.text = [NSString stringWithFormat:@"文件验证： %@", v];
}

- (void)start {
    __weak typeof(self) w = self;
    LLDownloadTask *task = [self.sessionManager downloadWithURL:kURLString
                                                         headers:nil
                                                        fileName:nil
                                                     onMainQueue:YES
                                                         handler:nil];
    [[[task onProgress:YES handler:^(id t) { [w updateUI:t]; }]
               onCompletion:YES handler:^(id t) { [w updateUI:t]; }]
     validateFileWithCode:kMD5 type:LLVerificationTypeMD5 onMainQueue:YES
                  handler:^(LLDownloadTask *t) { [w updateUI:t]; }];
}

- (void)suspend { [self.sessionManager suspendWithURL:kURLString onMainQueue:YES handler:nil]; }
- (void)cancelTask { [self.sessionManager cancelWithURL:kURLString onMainQueue:YES handler:nil]; }
- (void)deleteTask { [self.sessionManager removeWithURL:kURLString completely:NO onMainQueue:YES handler:nil]; }
- (void)clearDisk { [self.sessionManager.cache clearDiskCacheOnMainQueue:YES handler:nil]; }

@end
