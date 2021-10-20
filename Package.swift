// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "XcodeCodeCoverage2SQ",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(name: "xccodecoverage2sonarqube", targets: ["XcodeCodeCoverage2SQ"]),
        .library(name: "xccodecoverage2sonarqubelib", targets: ["XcodeCodeCoverage2SQCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.1"),
    ],
    targets: [
        .executableTarget(
            name: "XcodeCodeCoverage2SQ",
            dependencies: [
                "XcodeCodeCoverage2SQCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]),
        .target(
            name: "XcodeCodeCoverage2SQCore",
            dependencies: []),
        .testTarget(
            name: "XcodeCodeCoverage2SQCoreTests",
            dependencies: [
                "XcodeCodeCoverage2SQCore"
            ]),
    ]
)
