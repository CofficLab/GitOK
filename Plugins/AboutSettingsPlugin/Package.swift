// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AboutSettingsPlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "AboutSettingsPlugin", targets: ["AboutSettingsPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
        .package(path: "../../Packages/GitOKAppCore"),
        .package(path: "../../Packages/GitOKUI"),
        .package(path: "../../Packages/GitOKSupportKit"),
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.0"),
    ],
    targets: [
        .target(
            name: "AboutSettingsPlugin",
            dependencies: [
                "GitOKCoreKit",
                "GitOKAppCore",
                "GitOKUI",
                "GitOKSupportKit",
                .product(name: "Sparkle", package: "Sparkle"),
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")],
            swiftSettings: [
                .swiftLanguageMode(.v5),
            ]
        ),
        .testTarget(
            name: "AboutSettingsPluginTests",
            dependencies: ["AboutSettingsPlugin"],
            path: "Tests"
        ),
    ]
)
