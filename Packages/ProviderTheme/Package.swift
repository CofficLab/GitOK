// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProviderTheme",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "ProviderTheme", targets: ["ProviderTheme"]),
    ],
    dependencies: [
        .package(path: "../GitOKUI"),
    ],
    targets: [
        .target(
            name: "ProviderTheme",
            dependencies: ["GitOKUI"],
            path: "Sources"
        ),
    ]
)
