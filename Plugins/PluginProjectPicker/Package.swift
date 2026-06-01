// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginProjectPicker",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "PluginProjectPicker", targets: ["PluginProjectPicker"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "PluginProjectPicker",
            dependencies: [
                "GitOKCoreKit",
            ],
            path: "Sources/PluginProjectPicker",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginProjectPickerTests",
            dependencies: ["PluginProjectPicker"],
            path: "Tests"
        ),
    ]
)
