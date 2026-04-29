# LLDownloader-Demo

iOS demo app for [LLDownloader](../LLDownloader). Demonstrates every public-facing API on the library across four tabs.

## Tabs

| Tab | View controller | Demonstrates |
| --- | --- | --- |
| 单任务 | `SingleDownloadViewController` | Single URL, chainable `onProgress:` / `onCompletion:` / `validateFileWithCode:type:...`, start / suspend / cancel / remove / clear-disk buttons |
| 多任务 | `MultipleDownloadViewController` | Hand-add and hand-delete tasks; per-row pause/resume; batch controls (全部开始 / 暂停 / 取消 / 删除); concurrency + cellular toggles |
| 批量 | `BatchDownloadViewController` | `multiDownloadWithURLs:...` fired on a background queue against URLs in `VideoURLStrings.plist` |
| 列表 | `ListViewController` → `DownloadViewController` | Selectable file list that enqueues downloads into a shared manager, with a push-navigated management screen |

Shared UI lives in `DownloadTaskCell` (per-task row) and `BaseDownloadListViewController` (table + stats + switches).

Each tab is backed by its own `LLSessionManager` instance (configured in `AppDelegate`) so they have independent caches, task lists, and URL sessions.

## Requirements

- Xcode 13+
- iOS 13+ simulator or device

## Project layout

```
/Users/zyb/Project/
├── LLDownloader/          ← library (sibling directory)
│   ├── General/ Extensions/ Utility/
│   ├── LLDownloader.h  LLDownloader.podspec
└── LLDownloader-Demo/     ← this demo
    ├── Podfile
    ├── LLDownloader-Demo.xcodeproj
    ├── LLDownloader-Demo.xcworkspace   ← open this
    └── LLDownloader-Demo/              ← app sources
```

The demo consumes `../LLDownloader` as a **local CocoaPods pod** (`pod 'LLDownloader', :path => '../LLDownloader'`). The pod is installed as a static framework (`use_frameworks! :linkage => :static`), so `#import "LLDownloader.h"` in the sources just works — CocoaPods wires up the header search paths.

## Run

```sh
cd LLDownloader-Demo
pod install        # first time, or after editing LLDownloader.podspec
open LLDownloader-Demo.xcworkspace
```

Hit **Run** in Xcode and pick an iOS Simulator.

Command-line build:

```sh
xcodebuild -workspace LLDownloader-Demo.xcworkspace -scheme LLDownloader-Demo \
           -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
           -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

## Running on a real device

1. Open the workspace and select the `LLDownloader-Demo` target.
2. **Signing & Capabilities** → tick **Automatically manage signing** and pick your Team.
3. Change **Bundle Identifier** from the placeholder `com.ll.downloader.demo` to something unique you own (e.g. `com.<you>.ll.downloader.demo`).
4. Plug in a device, build & run.

Free Apple IDs work — you'll just need to trust the developer profile in **Settings → General → VPN & Device Management** on the device the first time.

## Notes

- UI is built entirely programmatically; there are no storyboards or xibs.
- `NSAppTransportSecurity.NSAllowsArbitraryLoads = YES` is set in `Info.plist` so the demo can hit the plain-HTTP sample URLs shipped with it. Remove for production.
- `UIBackgroundModes: fetch` is declared because LLDownloader uses a background `NSURLSession`.
- Sample URLs are public test files and may go stale over time; replace with your own for reliable demos.

## License

MIT — mirrors the [LLDownloader](../LLDownloader) license.
