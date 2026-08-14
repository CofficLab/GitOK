// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GitOKUpdateKit",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "GitOKUpdateKit",
            targets: ["GitOKUpdateKit"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/sparkle-project/Sparkle",
            from: "2.6.4"
        ),
    ],
    targets: [
        .target(
            name: "GitOKUpdateKit",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle"),
            ],
            path: "Sources"
        ),
    ]
)
