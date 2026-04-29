# LLDownloader

Lightweight Objective-C download framework built on `NSURLSession` background sessions. Handles large-file downloads, multi-task orchestration, resume-on-relaunch, persistent task state, checksum validation, and background app events.

## Repository layout

| Folder | Contents |
| --- | --- |
| [`LLDownloader/`](./LLDownloader) | Library sources + `LLDownloader.podspec` |
| [`LLDownloader-Demo/`](./LLDownloader-Demo) | iOS demo app consuming the library via a local CocoaPods pod |

## Features

- **Background `NSURLSession`** — downloads keep running after the app is suspended; resume after relaunch is automatic.
- **Single + multi-task orchestration** — start / suspend / cancel / remove individual tasks or all tasks at once.
- **Concurrency control** — configurable `maxConcurrentTasksLimit` (clamped to `[1, 6]`).
- **Resume support** — interrupted downloads resume from `resumeData` without re-transferring completed bytes.
- **Persistent task state** — task list is serialized via `NSSecureCoding` to a plist under the cache directory; fully restored on next launch.
- **File integrity** — built-in MD5 / SHA1 / SHA256 / SHA512 validation against a supplied code.
- **Speed + ETA** — per-task and aggregate speed (`bytes/s`) and time-remaining updated on a 1-second timer.
- **Chainable callbacks** — `onProgress:` / `onSuccess:` / `onFailure:` / `onCompletion:` on both tasks and session managers.
- **Notifications** — `NSNotificationCenter` events for running / completed state on tasks and managers.
- **Thread-safe** — internal state guarded by an `os_unfair_lock` wrapper (`LLUnfairLock`).
- **Header access policy tunables** — allow/deny cellular, constrained, and expensive network access.
- **Multiple isolated managers** — each with its own identifier, cache directory, operation queue, and URL session.
- **No external dependencies** — only Foundation, UIKit, and CommonCrypto (built into the SDK).

## Requirements

- iOS 12.0+
- Xcode 13+
- ARC

## Installation

### CocoaPods (local path)

```ruby
pod 'LLDownloader', :path => 'path/to/LLDownloader/LLDownloader'
```

The demo in this repo uses exactly this pattern — see [`LLDownloader-Demo/Podfile`](./LLDownloader-Demo/Podfile).

### CocoaPods (git)

```ruby
pod 'LLDownloader', :git => 'https://github.com/luoleionly/LLDownloader.git'
```

### Manual

Drag the [`LLDownloader/`](./LLDownloader) folder into your Xcode project (choose *Create groups*, link to your app target). All files are ARC-enabled. Then:

```objc
#import "LLDownloader.h"
```

## Try the demo

```sh
cd LLDownloader-Demo
pod install
open LLDownloader-Demo.xcworkspace
```

The demo has four tabs exercising single-task downloads, multi-task management, batch `multiDownload`, and a selectable file list. See [`LLDownloader-Demo/README.md`](./LLDownloader-Demo/README.md).

## Source layout

```
LLDownloader/
├── LLDownloader.h                 umbrella header
├── General/                       core types
│   ├── LLCommon.h/m               Status constants, LLLogType, LLLogger
│   ├── LLProtected.h/m            LLUnfairLock, LLDebouncer, LLThrottler
│   ├── LLError.h/m                NSError domain + factory methods
│   ├── LLNotifications.h/m        notification name constants
│   ├── LLExecuter.h/m             main-queue / caller-queue dispatch helper
│   ├── LLSessionConfiguration.h/m tunables (timeout, concurrency, cellular…)
│   ├── LLTask.h/m                 abstract task base + NSSecureCoding
│   ├── LLDownloadTask.h/m         concrete download task
│   ├── LLSessionDelegate.h/m      NSURLSessionDownloadDelegate glue
│   ├── LLSessionManager.h/m       public-facing download manager
│   └── LLCache.h/m                disk persistence + file layout
├── Extensions/                    Foundation category helpers
│   ├── NSArray+LLSafe.h/m         bounds-checked indexing
│   ├── NSData+LLHash.h/m          md5 / sha1 / sha256 / sha512
│   ├── NSString+LLHash.h/m        same, for strings
│   ├── NSString+LLURL.h/m         LLAsURL(id, NSError**)
│   ├── NSNumber+LLTaskInfo.h/m    bytes / speed / time string formatting
│   └── NSFileManager+LLAvailableCapacity.h/m
└── Utility/
    ├── LLResumeDataHelper.h/m     parse NSURLSessionResume plist blobs
    └── LLFileChecksumHelper.h/m   async file hashing + verification
```

## Core types

| Type | Role |
|---|---|
| `LLSessionManager` | Top-level entry point. Owns a background `NSURLSession`, the task list, configuration, cache, and aggregate state (speed / time-remaining / progress). |
| `LLDownloadTask` | Single download. Exposes `status` / `progress` / `speed` / `fileName` / `filePath` / `response`, chainable callbacks, and a KVO-observable `NSProgress`. |
| `LLSessionConfiguration` | Per-manager knobs. `timeoutIntervalForRequest`, `maxConcurrentTasksLimit` (clamped to 1–6), `allowsCellularAccess`, `allowsExpensiveNetworkAccess`, `allowsConstrainedNetworkAccess`. |
| `LLCache` | Disk layout (`Downloads/Tmp/`, `Downloads/File/`), task-list persistence, tmp-file bookkeeping, cache clearing. |
| `LLFileChecksumHelper` | Async MD5/SHA1/SHA256/SHA512 against a file path. |
| `LLLogger` / `<LLLogable>` | Pluggable logger. Default implementation prints a formatted banner. |

## Status lifecycle

A task / manager moves through the string-keyed states defined in `LLCommon.h`:

```
waiting → running → (succeeded | failed | suspended | canceled | removed)

            (user actions drive transient "will*" states)
```

| Constant | Meaning |
|---|---|
| `LLStatusWaiting` | Queued — over the concurrency limit |
| `LLStatusRunning` | Actively downloading |
| `LLStatusSucceeded` | Finished with an acceptable HTTP status (200–299) |
| `LLStatusFailed` | Network error / unacceptable status / checksum mismatch |
| `LLStatusSuspended` | Paused; resume data kept for fast-resume |
| `LLStatusCanceled` | User cancelled; tmp file discarded |
| `LLStatusRemoved` | Task purged from list |
| `LLStatusWillSuspend` / `LLStatusWillCancel` / `LLStatusWillRemove` | Transient — action requested, awaiting delegate callback |

## Quick start

```objc
#import "LLDownloader.h"

// 1. Build a manager
LLSessionConfiguration *cfg = [[LLSessionConfiguration alloc] init];
cfg.maxConcurrentTasksLimit = 3;

LLSessionManager *manager = [[LLSessionManager alloc] initWithIdentifier:@"download"
                                                           configuration:cfg];

// 2. Enqueue a download with chainable callbacks
LLDownloadTask *task = [manager downloadWithURL:@"https://example.com/file.zip"
                                        headers:nil
                                       fileName:nil
                                    onMainQueue:YES
                                        handler:nil];

[[[task onProgress:YES handler:^(LLDownloadTask *t) {
    NSLog(@"%.2f%% — %@", t.progress.fractionCompleted * 100, t.speedString);
}] onSuccess:YES handler:^(LLDownloadTask *t) {
    NSLog(@"done → %@", t.filePath);
}] onFailure:YES handler:^(LLDownloadTask *t) {
    NSLog(@"failed: %@", t.error);
}];
```

### Batch downloads

```objc
[manager multiDownloadWithURLs:@[@"https://.../a.mp4",
                                 @"https://.../b.mp4",
                                 @"https://.../c.mp4"]
                  headersArray:nil
                     fileNames:nil
                   onMainQueue:YES
                       handler:^(LLSessionManager *m) {
    NSLog(@"started %lu tasks", (unsigned long)m.tasks.count);
}];
```

### Checksum validation

```objc
[task validateFileWithCode:@"9e2a3650530b563da297c9246acaad5c"
                      type:LLVerificationTypeMD5
               onMainQueue:YES
                   handler:^(LLDownloadTask *t) {
    if (t.validation == LLValidationCorrect) { /* good */ }
}];
```

### Manager-level controls

```objc
[manager totalStartOnMainQueue:YES handler:nil];    // resume everything
[manager totalSuspendOnMainQueue:YES handler:nil];  // pause everything
[manager totalCancelOnMainQueue:YES handler:nil];   // cancel, keep row off the list
[manager totalRemoveCompletely:NO  onMainQueue:YES handler:nil]; // remove + keep on-disk files
```

### Aggregate progress

```objc
NSProgress *p = manager.progress;                   // combined across tasks
NSString *speed = manager.speedString;              // "512 KB/s"
NSString *eta   = manager.timeRemainingString;      // "0:03:21"
```

### Notifications

| Name | Posted when |
|---|---|
| `LLDownloadTaskRunningNotification` | Task wrote bytes |
| `LLDownloadTaskDidCompleteNotification` | Task reached a terminal status |
| `LLSessionManagerRunningNotification` | Any task in the manager wrote bytes |
| `LLSessionManagerDidCompleteNotification` | Manager reached a terminal status |

Access payloads via `notification.ll_downloadTask` / `.ll_sessionManager`.

## Background URLSession handoff

Add in your `AppDelegate`:

```objc
- (void)application:(UIApplication *)application
handleEventsForBackgroundURLSession:(NSString *)identifier
  completionHandler:(void (^)(void))completionHandler {
    if ([manager.identifier isEqualToString:identifier]) {
        manager.completionHandler = completionHandler;
    }
}
```

Declare `UIBackgroundModes: fetch` in `Info.plist`.

## Thread safety

All mutable state on `LLSessionManager`, `LLTask`, and `LLDownloadTask` is guarded by `LLUnfairLock` (a thin `os_unfair_lock` wrapper). Public APIs that perform lifecycle transitions dispatch onto the manager's `operationQueue` so callers don't need to serialize externally.

## Error reporting

Errors live in the `LLErrorDomain` domain with codes in `LLErrorCode` (see `LLDownloader/General/LLError.h`). Additional structured keys:

- `LLErrorURLKey` — offending URL for `InvalidURL` / `DuplicateURL` / `FetchDownloadTaskFailed`
- `LLErrorPathKey` / `LLErrorToPathKey` — path(s) for cache errors
- `LLErrorStatusCodeKey` — HTTP status code for `UnacceptableStatusCode`
- `NSUnderlyingErrorKey` — wrapped underlying error where applicable

File-checksum errors use a separate domain `LLFileVerificationErrorDomain`.

## License

MIT. See [`LLDownloader/LICENSE`](./LLDownloader/LICENSE).
