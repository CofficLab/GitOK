// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ActivityStatusPlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "ActivityStatusPlugin", targets: ["ActivityStatusPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "ActivityStatusPlugin",
            dependencies: ["GitOKCoreKit"],
            path: "Sources",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "ActivityStatusPluginTests",
            dependencies: ["ActivityStatusPlugin"],
            path: "Tests"
        ),
    ]
)
