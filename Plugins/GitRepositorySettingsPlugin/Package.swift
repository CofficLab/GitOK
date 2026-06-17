// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GitRepositorySettingsPlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "GitRepositorySettingsPlugin", targets: ["GitRepositorySettingsPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitCoreKit"),
        .package(path: "../../Packages/GitOKCoreKit"),
        .package(path: "../../Packages/GitOKAppCore"),
        .package(path: "../../Packages/GitOKUI"),
        .package(path: "../../Packages/GitOKSupportKit"),
        .package(path: "../../Packages/ProjectRulesKit"),
    ],
    targets: [
        .target(
            name: "GitRepositorySettingsPlugin",
            dependencies: [
                "GitCoreKit",
                "GitOKCoreKit",
                "GitOKAppCore",
                "GitOKUI",
                "GitOKSupportKit",
                "ProjectRulesKit",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")],
            swiftSettings: [
                .swiftLanguageMode(.v5),
            ]
        ),
        .testTarget(
            name: "GitRepositorySettingsPluginTests",
            dependencies: ["GitRepositorySettingsPlugin"],
            path: "Tests"
        ),
    ]
)
