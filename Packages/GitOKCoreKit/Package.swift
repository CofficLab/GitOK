// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GitOKCoreKit",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "GitOKCoreKit",
            targets: ["GitOKCoreKit"]
        ),
    ],
    dependencies: [
        .package(path: "../GitOKUI"),
    ],
    targets: [
        .target(
            name: "GitOKCoreKit",
            dependencies: [
                "GitOKUI",
            ],
            path: "Sources/GitOKCoreKit",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "GitOKCoreKitTests",
            dependencies: ["GitOKCoreKit"],
            path: "Tests"
        ),
    ]
)
