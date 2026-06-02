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
    dependencies: [
        .package(path: "../GitCoreKit"),
    ],
    targets: [
        .target(
            name: "ProjectRulesKit",
            dependencies: [
                "GitCoreKit",
            ],
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "ProjectRulesKitTests",
            dependencies: ["ProjectRulesKit"],
            path: "Tests"
        ),
    ]
)
