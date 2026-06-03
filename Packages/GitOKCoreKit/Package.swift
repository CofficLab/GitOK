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
        .library(
            name: "GitOKCoreFeatures",
            targets: ["GitOKCoreFeatures"]
        ),
    ],
    dependencies: [
        .package(path: "../GitOKUI"),
        .package(path: "../ProjectRulesKit"),
        .package(path: "../ProjectSupportKit"),
        .package(path: "../GitCoreKit"),
        .package(path: "../GitOKSupportKit"),
        .package(url: "https://github.com/nookery/MagicDiffView", branch: "main"),
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
        .target(
            name: "GitOKCoreFeatures",
            dependencies: [
                "GitOKCoreKit",
                "ProjectRulesKit",
                "ProjectSupportKit",
                "GitCoreKit",
                "GitOKSupportKit",
                "MagicDiffView",
            ],
            path: "Sources/GitOKCoreFeatures"
        ),
        .testTarget(
            name: "GitOKCoreKitTests",
            dependencies: ["GitOKCoreKit"],
            path: "Tests"
        ),
        .testTarget(
            name: "GitOKCoreFeaturesTests",
            dependencies: ["GitOKCoreFeatures"],
            path: "FeatureTests"
        ),
    ]
)
