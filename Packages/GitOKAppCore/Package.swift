// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GitOKAppCore",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "GitOKAppCore",
            targets: ["GitOKAppCore"]
        ),
    ],
    dependencies: [
        .package(path: "../GitCoreKit"),
        .package(path: "../GitOKCoreKit"),
        .package(path: "../GitOKSupportKit"),
        .package(path: "../ProjectRulesKit"),
        .package(path: "../ProjectSupportKit"),
        .package(path: "../GitOKUI"),
        .package(path: "../ProjectKit"),
    ],
    targets: [
        .target(
            name: "GitOKAppCore",
            dependencies: [
                "GitCoreKit",
                "GitOKCoreKit",
                "GitOKUI",
                "GitOKSupportKit",
                "ProjectRulesKit",
                "ProjectSupportKit",
                "ProjectKit",
            ],
            path: "Sources/GitOKAppCore",
            resources: [
                .process("Localizable.xcstrings")
            ]
        ),
    ]
)
