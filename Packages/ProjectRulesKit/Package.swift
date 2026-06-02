// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProjectRulesKit",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "ProjectRulesKit",
            targets: ["ProjectRulesKit"]
        ),
    ],
    dependencies: [
        .package(path: "../GitCoreKit"),
    ],
    targets: [
        .target(
            name: "ProjectRulesKit",
            dependencies: [
                "GitCoreKit",
            ]
        ),
        .testTarget(
            name: "ProjectRulesKitTests",
            dependencies: ["ProjectRulesKit"],
            path: "Tests"
        ),
    ]
)
