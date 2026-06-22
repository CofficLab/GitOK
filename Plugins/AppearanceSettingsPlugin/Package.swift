// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AppearanceSettingsPlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "AppearanceSettingsPlugin", targets: ["AppearanceSettingsPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
        .package(path: "../../Packages/GitOKUI"),
        .package(path: "../../Packages/GitOKSupportKit"),
    ],
    targets: [
        .target(
            name: "AppearanceSettingsPlugin",
            dependencies: [
                "GitOKCoreKit",
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
            name: "AppearanceSettingsPluginTests",
            dependencies: ["AppearanceSettingsPlugin"],
            path: "Tests"
        ),
    ]
)
