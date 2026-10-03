# SwiftBonjour

A small Swift package that wraps `NetService` / `NetServiceBrowser` (Bonjour) for
publishing, browsing and resolving services. On Linux it uses the
[Bouke/NetService](https://github.com/Bouke/NetService) package instead of Foundation.

## Layout

- `Sources/SwiftBonjour/` — the library: `BonjourServer`, `BonjourBrowser`,
  `BonjourResolver`, `BonjourLogger`, `ServiceType`, and `NetService` helpers
  (TXT records, `ipAddresses`). `IPAddress+Ext.swift` is a Linux-only shim for
  the Network framework's address types.
- `Tests/SwiftBonjourTests/` — a Swift Testing round trip against the real mDNS responder.
- `Example/` and `SwiftBonjour.xcworkspace` — SwiftUI example apps (Browser and Service,
  iOS and macOS) that use the package from the local checkout.

## Toolchain and platforms

- `swift-tools-version:6.2`, Swift 6 language mode (strict concurrency).
- Minimum platforms: iOS 15, macOS 12, tvOS 15, visionOS 1. Current Xcode rejects lower
  deployment targets. watchOS has no `NetService`; every library file is wrapped in
  `#if !os(watchOS)`, so the package builds but is empty there.
- Linux is supported through Bouke/NetService. It ignores `.listenForConnections` and
  `.noAutoRename`, needs an explicit port, and its objects cannot be restarted after
  `stop()`, which is why the server and browser recreate them on Linux.

## Commands

```sh
swift build
swift build -c release
swift test                 # also run with -c release
swiftformat .              # must leave `swiftformat --lint .` clean
```

Build the library for the other platforms with `xcodebuild -scheme SwiftBonjour
-destination 'generic/platform=iOS Simulator'` (likewise tvOS, visionOS and watchOS
Simulator) from a copy of the package without the workspace and example project, or the
example project's schemes shadow the package scheme. Build the example apps through the
workspace: `xcodebuild -workspace SwiftBonjour.xcworkspace -scheme "SwiftBonjour Browser (iOS)" ...`.

`swift test` publishes and browses a real service, so it needs a working local network.
It cannot pass in a VM or sandbox whose network is isolated from mDNS.

## Rules

- `NetService` and `NetServiceBrowser` deliver callbacks through the run loop of the
  thread that started them. Keep that requirement documented on `start` and `browse`.
  Do not "fix" it by spinning a run loop inside the library.
- The library classes are not thread-safe. Use each instance on one thread.
- `stop()` on the browser really stops the search, cancels pending resolves, empties
  `services` and calls `serviceRemovedHandler` for each removed service. Keep the
  round-trip test covering that.
- `LoggerLevel` filters by severity (`debug < info < default < error < fault`), never by
  `OSLogType.rawValue`, whose order on Apple platforms is not severity order.
- Do not change code-signing settings in the example project. The macOS Service target
  asks for an Apple Development identity and needs a team to be signed. Compile it with
  `CODE_SIGNING_ALLOWED=NO` when you only need to check that it builds.
- Format with the checked-in `.swiftformat` before committing.
- Public API is versioned with semver tags (`1.x`). Do not break it in a minor release.
