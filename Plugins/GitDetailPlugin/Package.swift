// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GitDetailPlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "GitDetailPlugin", targets: ["GitDetailPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "GitDetailPlugin",
            dependencies: ["GitOKCoreKit"],
            path: "Sources"
        ),
        .testTarget(
            name: "GitDetailPluginTests",
            dependencies: ["GitDetailPlugin"],
            path: "Tests"
        ),
    ]
)
