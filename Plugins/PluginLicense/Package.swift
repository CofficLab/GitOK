// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginLicense",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PluginLicense", targets: ["LicensePlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/KitGitOKCore"),
        .package(path: "../../Packages/KitProjectSupport"),
    ],
    targets: [
        .target(
            name: "LicensePlugin",
            dependencies: [
                "KitGitOKCore",
                "KitProjectSupport",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "LicensePluginTests",
            dependencies: [
                "LicensePlugin",
                "KitProjectSupport",
            ],
            path: "Tests"
        ),
    ]
)
