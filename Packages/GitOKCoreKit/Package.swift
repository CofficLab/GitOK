// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GitOKCoreKit",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
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
        .package(path: "../BannerCoreKit"),
        .package(path: "../ProjectSupportKit"),
        .package(path: "../GitCoreKit"),
        .package(path: "../MagicAlert"),
        .package(path: "../MagicKit"),
    ],
    targets: [
        .target(
            name: "GitOKCoreKit",
            dependencies: [
                "GitOKUI",
                "ProjectRulesKit",
                "BannerCoreKit",
                "ProjectSupportKit",
                "GitCoreKit",
                "MagicAlert",
                "MagicKit",
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
            ],
            path: "Sources/GitOKCoreFeatures"
        ),
        .testTarget(
            name: "GitOKCoreKitTests",
            dependencies: ["GitOKCoreKit"],
            path: "Tests"
        ),
    ]
)
