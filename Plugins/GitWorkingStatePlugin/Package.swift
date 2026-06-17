// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GitWorkingStatePlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "GitWorkingStatePlugin", targets: ["GitWorkingStatePlugin"]),
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
    ],
    targets: [
        .target(
            name: "GitWorkingStatePlugin",
            dependencies: [
                "GitCoreKit",
                "GitOKAppCore",
                "GitOKCoreKit",
                "GitOKSupportKit",
                "GitOKUI",
                "MagicAlert",
                "ProjectRulesKit",
                "ProjectSupportKit",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")],
            swiftSettings: [
                .swiftLanguageMode(.v5),
            ]
        ),
        .testTarget(
            name: "GitWorkingStatePluginTests",
            dependencies: ["GitWorkingStatePlugin"],
            path: "Tests"
        ),
    ]
)
