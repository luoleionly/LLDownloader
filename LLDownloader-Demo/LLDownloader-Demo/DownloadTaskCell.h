#import <UIKit/UIKit.h>
#import "LLDownloader.h"

NS_ASSUME_NONNULL_BEGIN

@class DownloadTaskCell;

@interface DownloadTaskCell : UITableViewCell

@property (nonatomic, class, readonly) NSString *reuseIdentifier;

@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UILabel *statusLabel;
@property (nonatomic, strong, readonly) UILabel *bytesLabel;
@property (nonatomic, strong, readonly) UILabel *speedLabel;
@property (nonatomic, strong, readonly) UILabel *timeRemainingLabel;
@property (nonatomic, strong, readonly) UILabel *startDateLabel;
@property (nonatomic, strong, readonly) UILabel *endDateLabel;
@property (nonatomic, strong, readonly) UIProgressView *progressView;
@property (nonatomic, strong, readonly) UIButton *controlButton;

@property (nonatomic, weak, nullable) LLDownloadTask *task;
@property (nonatomic, copy, nullable) void (^tapBlock)(DownloadTaskCell *cell);

- (void)updateProgress:(LLDownloadTask *)task;

@end

NS_ASSUME_NONNULL_END
