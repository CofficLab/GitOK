// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ThemeMatrixPlugin",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "ThemeMatrixPlugin",
            targets: ["ThemeMatrixPlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "ThemeMatrixPlugin",
            dependencies: [
                "GitOKCoreKit",
            ],
            path: "Sources",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "ThemeMatrixPluginTests",
            dependencies: ["ThemeMatrixPlugin"],
            path: "Tests"
        ),
    ]
)
