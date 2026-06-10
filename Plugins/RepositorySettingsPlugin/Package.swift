// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RepositorySettingsPlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "RepositorySettingsPlugin", targets: ["RepositorySettingsPlugin"]),
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
            name: "RepositorySettingsPlugin",
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
            name: "RepositorySettingsPluginTests",
            dependencies: ["RepositorySettingsPlugin"],
            path: "Tests"
        ),
    ]
)
