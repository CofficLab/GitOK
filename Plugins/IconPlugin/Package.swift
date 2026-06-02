// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "IconPlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "IconPlugin", targets: ["IconPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
        .package(path: "../../Packages/MagicAlert"),
        .package(path: "../../Packages/GitOKSupportKit"),
        .package(path: "../../Packages/ProjectRulesKit"),
        .package(url: "https://github.com/nookery/MagicLog.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "IconPlugin",
            dependencies: [
                "GitOKCoreKit",
                "MagicAlert",
                "GitOKSupportKit",
                "ProjectRulesKit",
                "MagicLog",
            ],
            path: "Sources",
            resources: [
                .process("Localizable.xcstrings"),
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "IconPluginTests",
            dependencies: ["IconPlugin"],
            path: "Tests"
        ),
    ]
)
