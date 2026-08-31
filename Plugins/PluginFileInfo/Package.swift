// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginFileInfo",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PluginFileInfo", targets: ["FileInfoPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/KitGitOKCore"),
    ],
    targets: [
        .target(
            name: "FileInfoPlugin",
            dependencies: ["KitGitOKCore"],
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
