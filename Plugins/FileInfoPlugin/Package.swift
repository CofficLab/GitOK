// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FileInfoPlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "FileInfoPlugin", targets: ["FileInfoPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "FileInfoPlugin",
            dependencies: ["GitOKCoreKit"],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "FileInfoPluginTests",
            dependencies: ["FileInfoPlugin"],
            path: "Tests"
        ),
    ]
)
