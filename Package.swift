// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MRZScanner",
    platforms: [.iOS(.v13), .macOS(.v10_15)],
    products: [
        .library(
            name: "MRZScanner",
            targets: ["MRZScanner"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/romanmazeev/MRZParser.git", .upToNextMajor(from: "1.1.3"))
    ],
    targets: [
        .target(
            name: "MRZScanner",
            dependencies: ["MRZParser"]
        ),
        .testTarget(
            name: "MRZScannerTests",
            dependencies: ["MRZScanner"]),
    ]
)
