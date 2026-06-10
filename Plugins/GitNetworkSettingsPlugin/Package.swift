// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GitNetworkSettingsPlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "GitNetworkSettingsPlugin", targets: ["GitNetworkSettingsPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitCoreKit"),
        .package(path: "../../Packages/GitOKCoreKit"),
        .package(path: "../../Packages/GitOKAppCore"),
        .package(path: "../../Packages/GitOKUI"),
        .package(path: "../../Packages/GitOKSupportKit"),
    ],
    targets: [
        .target(
            name: "GitNetworkSettingsPlugin",
            dependencies: [
                "GitCoreKit",
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
            name: "GitNetworkSettingsPluginTests",
            dependencies: ["GitNetworkSettingsPlugin"],
            path: "Tests"
        ),
    ]
)
