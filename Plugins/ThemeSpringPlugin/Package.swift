// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ThemeSpringPlugin",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "ThemeSpringPlugin",
            targets: ["ThemeSpringPlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "ThemeSpringPlugin",
            dependencies: [
                "GitOKCoreKit",
            ],
            path: "Sources",
            resources: [
                .process("Localizable.xcstrings"),
            ]
        ),
        .testTarget(
            name: "ThemeSpringPluginTests",
            dependencies: ["ThemeSpringPlugin"],
            path: "Tests"
        ),
    ]
)
