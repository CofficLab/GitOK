// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProviderProjectLanguages",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "ProviderProjectLanguages", targets: ["ProviderProjectLanguages"]),
    ],
    targets: [
        .target(
            name: "ProviderProjectLanguages",
            path: "Sources/ProviderProjectLanguages"
        ),
        .testTarget(
            name: "ProviderProjectLanguagesTests",
            dependencies: ["ProviderProjectLanguages"],
            path: "Tests/ProviderProjectLanguagesTests"
        ),
    ]
)
