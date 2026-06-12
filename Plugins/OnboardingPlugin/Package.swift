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
        .package(path: "../../Packages/GitOKCoreKit"),
        .package(path: "../../Packages/GitOKAppCore"),
        .package(path: "../../Packages/GitOKUI"),
        .package(path: "../../Packages/GitOKSupportKit"),
        .package(path: "../../Plugins/ProjectsPlugin"),
    ],
    targets: [
        .target(
            name: "OnboardingPlugin",
            dependencies: [
                "GitOKCoreKit",
                "GitOKAppCore",
                "GitOKUI",
                "GitOKSupportKit",
                "ProjectsPlugin",
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
