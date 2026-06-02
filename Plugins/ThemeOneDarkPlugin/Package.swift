// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ThemeOneDarkPlugin",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "ThemeOneDarkPlugin",
            targets: ["ThemeOneDarkPlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "ThemeOneDarkPlugin",
            dependencies: [
                "GitOKCoreKit",
            ],
            path: "Sources",
            resources: [
                .process("Localizable.xcstrings"),
            ]
        ),
        .testTarget(
            name: "ThemeOneDarkPluginTests",
            dependencies: ["ThemeOneDarkPlugin"],
            path: "Tests"
        ),
    ]
)

