// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LicensePlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "LicensePlugin", targets: ["LicensePlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
        .package(path: "../../Packages/ProjectSupportKit"),
    ],
    targets: [
        .target(
            name: "LicensePlugin",
            dependencies: [
                "GitOKCoreKit",
                "ProjectSupportKit",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "LicensePluginTests",
            dependencies: ["LicensePlugin"],
            path: "Tests"
        ),
    ]
)
