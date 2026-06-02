// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GitClonePlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "GitClonePlugin", targets: ["GitClonePlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitCoreKit"),
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "GitClonePlugin",
            dependencies: [
                "GitCoreKit",
                "GitOKCoreKit",
            ],
            path: "Sources",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "GitClonePluginTests",
            dependencies: ["GitClonePlugin"],
            path: "Tests"
        ),
    ]
)
