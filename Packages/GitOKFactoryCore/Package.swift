// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GitOKFactoryCore",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "GitOKFactoryCore",
            targets: ["GitOKFactoryCore"]
        ),
    ],
    dependencies: [
        .package(path: "../GitOKAppCore"),
        .package(path: "../GitOKCoreKit"),
        .package(path: "../GitOKUI"),
        .package(path: "../GitOKSupportKit"),
        .package(path: "../MagicAlert"),
        .package(path: "../ProjectKit"),
        .package(path: "../GitCoreKit"),
    ],
    targets: [
        .target(
            name: "GitOKFactoryCore",
            dependencies: [
                "GitOKAppCore",
                "GitOKCoreKit",
                "GitOKUI",
                "GitOKSupportKit",
                "MagicAlert",
                "ProjectKit",
                "GitCoreKit",
            ],
            path: "Sources"
        ),
    ]
)
