// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OpenTraePlugin",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "OpenTraePlugin", targets: ["OpenTraePlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "OpenTraePlugin",
            dependencies: ["GitOKCoreKit"],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "OpenTraePluginTests",
            dependencies: ["OpenTraePlugin"],
            path: "Tests"
        ),
    ]
)
