// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "UpdatePlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "UpdatePlugin", targets: ["UpdatePlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
        .package(path: "../../Packages/GitOKAppCore"),
        .package(path: "../../Packages/GitOKUI"),
        .package(path: "../../Packages/GitOKSupportKit"),
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.4"),
    ],
    targets: [
        .target(
            name: "UpdatePlugin",
            dependencies: [
                "GitOKCoreKit",
                "GitOKAppCore",
                "GitOKUI",
                "GitOKSupportKit",
                .product(name: "Sparkle", package: "Sparkle"),
            ],
            path: "Sources/UpdatePlugin",
            swiftSettings: [
                .swiftLanguageMode(.v5),
            ]
        ),
        .testTarget(
            name: "UpdatePluginTests",
            dependencies: ["UpdatePlugin"],
            path: "Tests/UpdatePluginTests"
        ),
    ]
)