// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OnboardingPlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "OnboardingPlugin", targets: ["OnboardingPlugin"]),
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
            name: "OnboardingPlugin",
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
            name: "OnboardingPluginTests",
            dependencies: ["OnboardingPlugin"],
            path: "Tests"
        ),
    ]
)
