// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ReadmePlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "ReadmePlugin", targets: ["ReadmePlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "ReadmePlugin",
            dependencies: [
                "GitOKCoreKit",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "ReadmePluginTests",
            dependencies: ["ReadmePlugin"],
            path: "Tests"
        ),
    ]
)
