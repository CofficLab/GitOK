// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ThemeMidnightPlugin",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "ThemeMidnightPlugin",
            targets: ["ThemeMidnightPlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "ThemeMidnightPlugin",
            dependencies: [
                "GitOKCoreKit",
            ],
            path: "Sources",
            resources: [
                .process("Localizable.xcstrings"),
            ]
        ),
        .testTarget(
            name: "ThemeMidnightPluginTests",
            dependencies: ["ThemeMidnightPlugin"],
            path: "Tests"
        ),
    ]
)
