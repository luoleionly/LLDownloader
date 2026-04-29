#import "DownloadTaskCell.h"

@implementation DownloadTaskCell

+ (NSString *)reuseIdentifier { return @"DownloadTaskCell"; }

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self buildUI];
    }
    return self;
}

- (UILabel *)makeLabel:(UIFont *)font color:(UIColor *)color {
    UILabel *l = [[UILabel alloc] init];
    l.font = font;
    l.textColor = color;
    l.translatesAutoresizingMaskIntoConstraints = NO;
    return l;
}

- (void)buildUI {
    _titleLabel = [self makeLabel:[UIFont boldSystemFontOfSize:14] color:UIColor.labelColor];
    _titleLabel.numberOfLines = 0;
    _statusLabel = [self makeLabel:[UIFont systemFontOfSize:13] color:UIColor.secondaryLabelColor];
    _bytesLabel = [self makeLabel:[UIFont systemFontOfSize:12] color:UIColor.secondaryLabelColor];
    _speedLabel = [self makeLabel:[UIFont systemFontOfSize:12] color:UIColor.secondaryLabelColor];
    _timeRemainingLabel = [self makeLabel:[UIFont systemFontOfSize:12] color:UIColor.secondaryLabelColor];
    _startDateLabel = [self makeLabel:[UIFont systemFontOfSize:11] color:UIColor.tertiaryLabelColor];
    _endDateLabel = [self makeLabel:[UIFont systemFontOfSize:11] color:UIColor.tertiaryLabelColor];

    _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    _progressView.translatesAutoresizingMaskIntoConstraints = NO;

    _controlButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _controlButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_controlButton setTitle:@"⏸" forState:UIControlStateNormal];
    _controlButton.titleLabel.font = [UIFont systemFontOfSize:22];
    [_controlButton addTarget:self action:@selector(tapControl) forControlEvents:UIControlEventTouchUpInside];

    UIView *c = self.contentView;
    for (UIView *v in @[_titleLabel, _statusLabel, _bytesLabel, _speedLabel, _timeRemainingLabel, _startDateLabel, _endDateLabel, _progressView, _controlButton]) {
        [c addSubview:v];
    }

    [NSLayoutConstraint activateConstraints:@[
        [_titleLabel.leadingAnchor constraintEqualToAnchor:c.leadingAnchor constant:12],
        [_titleLabel.topAnchor constraintEqualToAnchor:c.topAnchor constant:10],
        [_titleLabel.trailingAnchor constraintEqualToAnchor:_controlButton.leadingAnchor constant:-8],

        [_controlButton.trailingAnchor constraintEqualToAnchor:c.trailingAnchor constant:-12],
        [_controlButton.centerYAnchor constraintEqualToAnchor:_titleLabel.centerYAnchor],
        [_controlButton.widthAnchor constraintEqualToConstant:40],
        [_controlButton.heightAnchor constraintEqualToConstant:40],

        [_progressView.leadingAnchor constraintEqualToAnchor:c.leadingAnchor constant:12],
        [_progressView.trailingAnchor constraintEqualToAnchor:c.trailingAnchor constant:-12],
        [_progressView.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:8],

        [_statusLabel.leadingAnchor constraintEqualToAnchor:c.leadingAnchor constant:12],
        [_statusLabel.topAnchor constraintEqualToAnchor:_progressView.bottomAnchor constant:6],
        [_speedLabel.trailingAnchor constraintEqualToAnchor:c.trailingAnchor constant:-12],
        [_speedLabel.centerYAnchor constraintEqualToAnchor:_statusLabel.centerYAnchor],

        [_bytesLabel.leadingAnchor constraintEqualToAnchor:c.leadingAnchor constant:12],
        [_bytesLabel.topAnchor constraintEqualToAnchor:_statusLabel.bottomAnchor constant:4],
        [_timeRemainingLabel.trailingAnchor constraintEqualToAnchor:c.trailingAnchor constant:-12],
        [_timeRemainingLabel.centerYAnchor constraintEqualToAnchor:_bytesLabel.centerYAnchor],

        [_startDateLabel.leadingAnchor constraintEqualToAnchor:c.leadingAnchor constant:12],
        [_startDateLabel.topAnchor constraintEqualToAnchor:_bytesLabel.bottomAnchor constant:4],
        [_endDateLabel.trailingAnchor constraintEqualToAnchor:c.trailingAnchor constant:-12],
        [_endDateLabel.centerYAnchor constraintEqualToAnchor:_startDateLabel.centerYAnchor],
        [_startDateLabel.bottomAnchor constraintEqualToAnchor:c.bottomAnchor constant:-10],
    ]];
}

- (void)tapControl {
    if (_tapBlock) _tapBlock(self);
}

- (void)updateProgress:(LLDownloadTask *)task {
    self.progressView.observedProgress = task.progress;
    NSString *done = [@(task.progress.completedUnitCount) ll_convertBytesToString];
    NSString *total = [@(task.progress.totalUnitCount) ll_convertBytesToString];
    self.bytesLabel.text = [NSString stringWithFormat:@"%@/%@", done, total];
    self.speedLabel.text = task.speedString;
    self.timeRemainingLabel.text = [NSString stringWithFormat:@"剩余时间：%@", task.timeRemainingString];
    self.startDateLabel.text = [NSString stringWithFormat:@"开始：%@", task.startDateString];
    self.endDateLabel.text = [NSString stringWithFormat:@"结束：%@", task.endDateString];

    NSString *btn = @"⏸";
    if ([task.status isEqualToString:LLStatusSuspended]) {
        self.statusLabel.text = @"暂停"; self.statusLabel.textColor = UIColor.labelColor; btn = @"▶";
    } else if ([task.status isEqualToString:LLStatusRunning]) {
        self.statusLabel.text = @"下载中"; self.statusLabel.textColor = UIColor.systemBlueColor; btn = @"⏸";
    } else if ([task.status isEqualToString:LLStatusSucceeded]) {
        self.statusLabel.text = @"成功"; self.statusLabel.textColor = UIColor.systemGreenColor; btn = @"✓";
    } else if ([task.status isEqualToString:LLStatusFailed]) {
        self.statusLabel.text = @"失败"; self.statusLabel.textColor = UIColor.systemRedColor; btn = @"!";
    } else if ([task.status isEqualToString:LLStatusWaiting]) {
        self.statusLabel.text = @"等待中"; self.statusLabel.textColor = UIColor.systemOrangeColor; btn = @"⋯";
    }
    [self.controlButton setTitle:btn forState:UIControlStateNormal];
}

@end
