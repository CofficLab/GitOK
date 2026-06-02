// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OpenFinderPlugin",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "OpenFinderPlugin",
            targets: ["OpenFinderPlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "OpenFinderPlugin",
            dependencies: ["GitOKCoreKit"],
            path: "Sources",
            resources: [
                .process("Localizable.xcstrings"),
            ]
        ),
        .testTarget(
            name: "OpenFinderPluginTests",
            dependencies: ["OpenFinderPlugin"],
            path: "Tests"
        ),
    ]
)
