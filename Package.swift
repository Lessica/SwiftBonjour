// swift-tools-version:5.3
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
    platforms: [.macOS(.v10_12),
                .iOS(.v10),
                .tvOS(.v10)],
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
    ]
)
