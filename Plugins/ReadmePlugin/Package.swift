// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ReadmePlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "ReadmePlugin", targets: ["ReadmePlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
        .package(path: "../../Packages/ProjectSupportKit"),
    ],
    targets: [
        .target(
            name: "ReadmePlugin",
            dependencies: [
                "GitOKCoreKit",
                "ProjectSupportKit",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "ReadmePluginTests",
            dependencies: [
                "ReadmePlugin",
                "ProjectSupportKit",
            ],
            path: "Tests"
        ),
    ]
)
