// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginLicense",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "PluginLicense", targets: ["PluginLicense"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKPluginKit"),
        .package(path: "../../Packages/ProjectSupportKit"),
    ],
    targets: [
        .target(
            name: "PluginLicense",
            dependencies: [
                "GitOKPluginKit",
                "ProjectSupportKit",
            ],
            path: "Sources/PluginLicense",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginLicenseTests",
            dependencies: ["PluginLicense"],
            path: "Tests/PluginLicenseTests"
        ),
    ]
)
