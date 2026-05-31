// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProjectRulesKit",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "ProjectRulesKit",
            targets: ["ProjectRulesKit"]
        ),
    ],
    targets: [
        .target(
            name: "ProjectRulesKit"
        ),
        .testTarget(
            name: "ProjectRulesKitTests",
            dependencies: ["ProjectRulesKit"],
            path: "Tests"
        ),
    ]
)
