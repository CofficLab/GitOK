// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GitDetailPlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "GitDetailPlugin", targets: ["GitDetailPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitCoreKit"),
        .package(path: "../../Packages/GitOKAppCore"),
        .package(path: "../../Packages/GitOKCoreKit"),
        .package(path: "../../Packages/GitOKSupportKit"),
        .package(path: "../../Packages/GitOKUI"),
        .package(path: "../../Packages/MagicAlert"),
        .package(path: "../../Packages/ProjectRulesKit"),
        .package(path: "../../Packages/ProjectSupportKit"),
        .package(url: "https://github.com/nookery/MagicDiffView", branch: "main"),
    ],
    targets: [
        .target(
            name: "GitDetailPlugin",
            dependencies: [
                "GitCoreKit",
                "GitOKAppCore",
                "GitOKCoreKit",
                "GitOKSupportKit",
                "GitOKUI",
                "MagicAlert",
                "ProjectRulesKit",
                "ProjectSupportKit",
                "MagicDiffView",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")],
            swiftSettings: [
                .swiftLanguageMode(.v5),
            ]
        ),
        .testTarget(
            name: "GitDetailPluginTests",
            dependencies: ["GitDetailPlugin"],
            path: "Tests"
        ),
    ]
)
