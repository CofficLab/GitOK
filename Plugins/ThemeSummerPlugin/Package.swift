// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ThemeSummerPlugin",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "ThemeSummerPlugin",
            targets: ["ThemeSummerPlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "ThemeSummerPlugin",
            dependencies: [
                "GitOKCoreKit",
            ],
            path: "Sources",
            resources: [
                .process("Localizable.xcstrings"),
            ]
        ),
        .testTarget(
            name: "ThemeSummerPluginTests",
            dependencies: ["ThemeSummerPlugin"],
            path: "Tests"
        ),
    ]
)

