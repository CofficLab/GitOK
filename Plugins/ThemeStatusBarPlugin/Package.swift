// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ThemeStatusBarPlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "ThemeStatusBarPlugin", targets: ["ThemeStatusBarPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "ThemeStatusBarPlugin",
            dependencies: [
                "GitOKCoreKit",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "ThemeStatusBarPluginTests",
            dependencies: ["ThemeStatusBarPlugin"],
            path: "Tests"
        ),
    ]
)
