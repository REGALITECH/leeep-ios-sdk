// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "leeep-ios-sdk",
    products: [
        .library(
            name: "leeep-ios-sdk",
            targets: ["leeep-ios-sdk"]),
    ],
    targets: [
        .binaryTarget(
            name: "leeep-ios-sdk",
            path: "./leeep-ios-sdk.xcframework"),
    ]
)
