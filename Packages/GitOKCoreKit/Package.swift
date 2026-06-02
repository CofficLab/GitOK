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
        .package(path: "../ProjectSupportKit"),
        .package(path: "../GitCoreKit"),
        .package(path: "../GitOKSupportKit"),
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
