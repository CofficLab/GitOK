// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProjectRulesKit",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "ProjectRulesKit",
            targets: ["ProjectRulesKit"]
        ),
    ],
    targets: [
        .target(
            name: "ProjectRulesKit",
            resources: []
        ),
        .testTarget(
            name: "ProjectRulesKitTests",
            dependencies: ["ProjectRulesKit"],
            path: "Tests"
        ),
    ]
)
