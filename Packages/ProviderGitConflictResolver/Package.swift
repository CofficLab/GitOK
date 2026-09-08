// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProviderGitConflictResolver",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "ProviderGitConflictResolver",
            targets: ["ProviderGitConflictResolver"]
        ),
    ],
    targets: [
        .target(
            name: "ProviderGitConflictResolver",
            path: "Sources/ProviderGitConflictResolver"
        ),
    ]
)
