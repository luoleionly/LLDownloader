#import <UIKit/UIKit.h>
#import "LLDownloader.h"

NS_ASSUME_NONNULL_BEGIN

@interface BaseDownloadListViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) LLSessionManager *sessionManager;
@property (nonatomic, copy) NSArray<NSString *> *URLStrings;

@property (nonatomic, strong, readonly) UITableView *tableView;
@property (nonatomic, strong, readonly) UILabel *totalTasksLabel;
@property (nonatomic, strong, readonly) UILabel *totalSpeedLabel;
@property (nonatomic, strong, readonly) UILabel *timeRemainingLabel;
@property (nonatomic, strong, readonly) UILabel *totalProgressLabel;
@property (nonatomic, strong, readonly) UISwitch *taskLimitSwitch;
@property (nonatomic, strong, readonly) UISwitch *cellularAccessSwitch;

- (void)setupManager;
- (void)updateUI;

@end

NS_ASSUME_NONNULL_END
