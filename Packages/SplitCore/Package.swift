// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SplitCore",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(name: "SplitCore", targets: ["SplitCore"])
    ],
    targets: [
        .target(name: "SplitCore"),
        .testTarget(
            name: "SplitCoreTests",
            dependencies: ["SplitCore"]
        )
    ]
)
