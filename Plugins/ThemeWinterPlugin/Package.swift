// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ThemeWinterPlugin",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "ThemeWinterPlugin",
            targets: ["ThemeWinterPlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "ThemeWinterPlugin",
            dependencies: [
                "GitOKCoreKit",
            ],
            path: "Sources",
            resources: [
                .process("Localizable.xcstrings"),
            ]
        ),
        .testTarget(
            name: "ThemeWinterPluginTests",
            dependencies: ["ThemeWinterPlugin"],
            path: "Tests"
        ),
    ]
)

