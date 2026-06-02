// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "IconTabPlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "IconTabPlugin", targets: ["IconTabPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "IconTabPlugin",
            dependencies: ["GitOKCoreKit"],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "IconTabPluginTests",
            dependencies: ["IconTabPlugin"],
            path: "Tests"
        ),
    ]
)
