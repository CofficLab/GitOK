// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginDiagnosticsSettings",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PluginDiagnosticsSettings", targets: ["DiagnosticsSettingsPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/KitGitOKCore"),
        .package(path: "../../Packages/GitOKAppCore"),
        .package(path: "../../Packages/GitOKUI"),
        .package(path: "../../Packages/KitGitOKSupport"),
    ],
    targets: [
        .target(
            name: "DiagnosticsSettingsPlugin",
            dependencies: [
                "KitGitOKCore",
                "GitOKAppCore",
                "GitOKUI",
                "KitGitOKSupport",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")],
            swiftSettings: [
                .swiftLanguageMode(.v5),
            ]
        ),
        .testTarget(
            name: "DiagnosticsSettingsPluginTests",
            dependencies: ["DiagnosticsSettingsPlugin"],
            path: "Tests"
        ),
    ]
)
