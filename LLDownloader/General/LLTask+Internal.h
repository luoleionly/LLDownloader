//
//  LLTask+Internal.h
//  LLDownloader
//
//  Exposes mutable internals shared between LLTask and subclasses / the
//  session manager. Not part of the public API.
//

#import "LLTask.h"
#import "LLProtected.h"
#import "LLExecuter.h"

NS_ASSUME_NONNULL_BEGIN

@interface LLTask () {
@protected
    LLUnfairLock *_stateLock;

    // State guarded by _stateLock
    NSURLSession *_session_;
    NSDictionary<NSString *, NSString *> *_headers_;
    NSString *_verificationCode_;
    LLVerificationType _verificationType_;
    BOOL _isRemoveCompletely_;
    LLStatus _status_;
    LLValidation _validation_;
    NSURL *_currentURL_;
    NSTimeInterval _startDate_;
    NSTimeInterval _endDate_;
    int64_t _speed_;
    NSString *_fileName_;
    int64_t _timeRemaining_;
    NSError *_error_;

    LLExecuter *_progressExecuter_;
    LLExecuter *_successExecuter_;
    LLExecuter *_failureExecuter_;
    LLExecuter *_completionExecuter_;
    LLExecuter *_controlExecuter_;
    LLExecuter *_validateExecuter_;
}

// Scoped read/write under _stateLock.
- (void)_withState:(NS_NOESCAPE void (^)(void))block;
- (id _Nullable)_readState:(NS_NOESCAPE id _Nullable (^)(void))block;

// Executer accessors
@property (nonatomic, strong, nullable) LLExecuter *progressExecuter;
@property (nonatomic, strong, nullable) LLExecuter *successExecuter;
@property (nonatomic, strong, nullable) LLExecuter *failureExecuter;
@property (nonatomic, strong, nullable) LLExecuter *completionExecuter;
@property (nonatomic, strong, nullable) LLExecuter *controlExecuter;
@property (nonatomic, strong, nullable) LLExecuter *validateExecuter;

// Sets status WITHOUT emitting a log (used during deserialization / state normalization).
- (void)_setStatusSilently:(LLStatus)status;

@end

NS_ASSUME_NONNULL_END
