// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GitOKUI",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "GitOKUI",
            targets: ["GitOKUI"]
        )
    ],
    targets: [
        .target(
            name: "GitOKUI",
            path: "Sources/GitOKUI"
        ),
        .testTarget(
            name: "GitOKUITests",
            dependencies: ["GitOKUI"],
            path: "Tests/GitOKUITests"
        )
    ]
)
