// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OpenVSCodePlugin",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "OpenVSCodePlugin",
            targets: ["OpenVSCodePlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "OpenVSCodePlugin",
            dependencies: ["GitOKCoreKit"],
            path: "Sources",
            resources: [
                .process("Localizable.xcstrings"),
            ]
        ),
        .testTarget(
            name: "OpenVSCodePluginTests",
            dependencies: ["OpenVSCodePlugin"],
            path: "Tests"
        ),
    ]
)
