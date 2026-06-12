// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CommitStyleSettingsPlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "CommitStyleSettingsPlugin", targets: ["CommitStyleSettingsPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
        .package(path: "../../Packages/GitOKAppCore"),
        .package(path: "../../Packages/GitOKUI"),
        .package(path: "../../Packages/GitOKSupportKit"),
    ],
    targets: [
        .target(
            name: "CommitStyleSettingsPlugin",
            dependencies: [
                "GitOKCoreKit",
                "GitOKAppCore",
                "GitOKUI",
                "GitOKSupportKit",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")],
            swiftSettings: [
                .swiftLanguageMode(.v5),
            ]
        ),
        .testTarget(
            name: "CommitStyleSettingsPluginTests",
            dependencies: ["CommitStyleSettingsPlugin"],
            path: "Tests"
        ),
    ]
)
