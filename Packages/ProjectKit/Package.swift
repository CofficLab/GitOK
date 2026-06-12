// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProjectKit",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "ProjectKit",
            targets: ["ProjectKit"]
        ),
    ],
    dependencies: [
        .package(path: "../GitCoreKit"),
        .package(path: "../ProjectRulesKit"),
        .package(path: "../GitOKCoreKit"),
        .package(path: "../GitOKSupportKit"),
    ],
    targets: [
        .target(
            name: "ProjectKit",
            dependencies: [
                "GitCoreKit",
                "ProjectRulesKit",
                "GitOKCoreKit",
                "GitOKSupportKit",
            ],
            path: "Sources"
        ),
    ]
)
