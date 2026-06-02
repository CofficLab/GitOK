// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ThemeEmberPlugin",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "ThemeEmberPlugin",
            targets: ["ThemeEmberPlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "ThemeEmberPlugin",
            dependencies: [
                "GitOKCoreKit",
            ],
            path: "Sources",
            resources: [
                .process("Localizable.xcstrings"),
            ]
        ),
        .testTarget(
            name: "ThemeEmberPluginTests",
            dependencies: ["ThemeEmberPlugin"],
            path: "Tests"
        ),
    ]
)
