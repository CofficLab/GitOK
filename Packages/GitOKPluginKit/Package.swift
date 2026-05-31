// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GitOKPluginKit",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "GitOKPluginKit",
            targets: ["GitOKPluginKit"]
        ),
    ],
    dependencies: [
        .package(path: "../GitOKUI"),
    ],
    targets: [
        .target(
            name: "GitOKPluginKit",
            dependencies: ["GitOKUI"],
            path: "Sources/GitOKPluginKit"
        ),
        .testTarget(
            name: "GitOKPluginKitTests",
            dependencies: ["GitOKPluginKit"],
            path: "Tests"
        ),
    ]
)
