// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ThemeGraphitePlugin",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "ThemeGraphitePlugin",
            targets: ["ThemeGraphitePlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "ThemeGraphitePlugin",
            dependencies: [
                "GitOKCoreKit",
            ],
            path: "Sources",
            resources: [
                .process("Localizable.xcstrings"),
            ]
        ),
        .testTarget(
            name: "ThemeGraphitePluginTests",
            dependencies: ["ThemeGraphitePlugin"],
            path: "Tests"
        ),
    ]
)

