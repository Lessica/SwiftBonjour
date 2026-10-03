// swift-tools-version:6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

#if os(Linux)
let dependencies: [Package.Dependency] = [
    .package(url: "https://github.com/Bouke/NetService.git", from: "0.8.1"),
]
let dependencyNames: [Target.Dependency] = ["NetService"]
#else
let dependencies: [Package.Dependency] = []
let dependencyNames: [Target.Dependency] = []
#endif

let package = Package(
    name: "SwiftBonjour",
    platforms: [.iOS(.v15),
                .macOS(.v12),
                .tvOS(.v15),
                .visionOS(.v1)],
    products: [
        .library(
            name: "SwiftBonjour",
            targets: ["SwiftBonjour"]),
    ],
    dependencies: dependencies,
    targets: [
        .target(
            name: "SwiftBonjour",
            dependencies: dependencyNames),
    ],
    swiftLanguageModes: [.v6]
)
