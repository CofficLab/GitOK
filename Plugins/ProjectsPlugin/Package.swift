// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProjectsPlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "ProjectsPlugin", targets: ["ProjectsPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
        .package(path: "../../Packages/GitOKAppCore"),
        .package(path: "../../Packages/GitOKUI"),
        .package(path: "../../Packages/GitOKSupportKit"),
        .package(path: "../../Packages/ProjectRulesKit"),
    ],
    targets: [
        .target(
            name: "ProjectsPlugin",
            dependencies: [
                "GitOKCoreKit",
                "GitOKAppCore",
                "GitOKUI",
                "GitOKSupportKit",
                "ProjectRulesKit",
            ],
            path: "Sources",
            resources: [
                .process("Localizable.xcstrings"),
                .process("Views/CloneRepository/GitCloneLocalizable.xcstrings"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5),
            ]
        ),
        .testTarget(
            name: "ProjectsPluginTests",
            dependencies: ["ProjectsPlugin"],
            path: "Tests"
        ),
    ]
)
