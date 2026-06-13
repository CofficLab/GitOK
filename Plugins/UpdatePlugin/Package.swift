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
    ],
    targets: [
        .target(
            name: "UpdatePlugin",
            dependencies: [
                "GitOKCoreKit",
                "GitOKAppCore",
                "GitOKUI",
                "GitOKSupportKit",
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