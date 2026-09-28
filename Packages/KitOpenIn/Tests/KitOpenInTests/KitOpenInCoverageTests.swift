import Foundation
import XCTest
@testable import KitOpenIn

final class OpenTargetCoverageTests: XCTestCase {

    func testAllSystemImagesNonEmptyAndUniqueWhereExpected() {
        // 每个 case 的 switch 都应被命中；这里逐项断言，避免编译器把 switch 当成单一分支。
        XCTAssertEqual(OpenTarget.finder.systemImage, "folder")
        XCTAssertEqual(OpenTarget.terminal.systemImage, "terminal")
        XCTAssertEqual(OpenTarget.vscode.systemImage, "chevron.left.forwardslash.chevron.right")
        XCTAssertEqual(OpenTarget.trae.systemImage, "chevron.left.forwardslash.chevron.right")
        XCTAssertEqual(OpenTarget.cursor.systemImage, "cursorarrow")
        XCTAssertEqual(OpenTarget.xcode.systemImage, "hammer")
        XCTAssertEqual(OpenTarget.antigravity.systemImage, "paperplane")
        XCTAssertEqual(OpenTarget.githubDesktop.systemImage, "arrow.triangle.branch")
        XCTAssertEqual(OpenTarget.kiro.systemImage, "sparkles")
        XCTAssertEqual(OpenTarget.lumi.systemImage, "sparkle")
        XCTAssertEqual(OpenTarget.remote.systemImage, "link")
    }

    func testAllDisplayNames() {
        XCTAssertEqual(OpenTarget.finder.displayName, "Finder")
        XCTAssertEqual(OpenTarget.terminal.displayName, "Terminal")
        XCTAssertEqual(OpenTarget.vscode.displayName, "VS Code")
        XCTAssertEqual(OpenTarget.cursor.displayName, "Cursor")
        XCTAssertEqual(OpenTarget.xcode.displayName, "Xcode")
        XCTAssertEqual(OpenTarget.trae.displayName, "Trae")
        XCTAssertEqual(OpenTarget.antigravity.displayName, "Antigravity")
        XCTAssertEqual(OpenTarget.githubDesktop.displayName, "GitHub Desktop")
        XCTAssertEqual(OpenTarget.kiro.displayName, "Kiro")
        XCTAssertEqual(OpenTarget.lumi.displayName, "Lumi")
        XCTAssertEqual(OpenTarget.remote.displayName, "Remote")
    }

    func testToolbarOrderIsMonotonic() {
        let orders = OpenTarget.allCases.map(\.toolbarOrder)
        XCTAssertEqual(orders, orders.sorted())
        XCTAssertEqual(Set(orders).count, orders.count)
        XCTAssertEqual(OpenTarget.remote.toolbarOrder, 110)
    }

    func testBundleIdentifiers() {
        XCTAssertEqual(OpenTarget.finder.bundleIdentifier, "com.apple.finder")
        XCTAssertEqual(OpenTarget.terminal.bundleIdentifier, "com.apple.Terminal")
        XCTAssertEqual(OpenTarget.vscode.bundleIdentifier, "com.microsoft.VSCode")
        XCTAssertEqual(OpenTarget.cursor.bundleIdentifier, "com.todesktop.230313mzl4w4u92")
        XCTAssertEqual(OpenTarget.xcode.bundleIdentifier, "com.apple.dt.Xcode")
        XCTAssertEqual(OpenTarget.trae.bundleIdentifier, "com.trae.app")
        XCTAssertEqual(OpenTarget.antigravity.bundleIdentifier, "com.google.antigravity")
        XCTAssertEqual(OpenTarget.githubDesktop.bundleIdentifier, "com.github.GitHubClient")
        XCTAssertEqual(OpenTarget.kiro.bundleIdentifier, "dev.kiro.desktop")
        XCTAssertEqual(OpenTarget.lumi.bundleIdentifier, "com.coffic.lumi")
        XCTAssertEqual(OpenTarget.remote.bundleIdentifier, "")
    }

    func testFallbackPaths() {
        // Finder / Terminal 是 macOS 必装，路径应存在。
        XCTAssertFalse(OpenTarget.finder.fallbackPaths.isEmpty)
        XCTAssertFalse(OpenTarget.terminal.fallbackPaths.isEmpty)
        // Remote 无回退路径。
        XCTAssertTrue(OpenTarget.remote.fallbackPaths.isEmpty)
        // 其他目标至少有一个 /Applications 候选。
        for target in OpenTarget.allCases where target != .remote {
            XCTAssertFalse(target.fallbackPaths.isEmpty, "target=\(target)")
        }
    }

    func testIdIsRawValue() {
        for target in OpenTarget.allCases {
            XCTAssertEqual(target.id, target.rawValue)
        }
    }
}

final class AppLauncherCoverageTests: XCTestCase {

    func testWebURLEdgeCases() {
        // https 无 .git 后缀
        XCTAssertEqual(
            AppLauncher.webURL(fromRemote: "https://github.com/user/repo")?.absoluteString,
            "https://github.com/user/repo"
        )
        // ssh:// 无 .git
        XCTAssertEqual(
            AppLauncher.webURL(fromRemote: "ssh://git@github.com/user/repo")?.absoluteString,
            "https://github.com/user/repo"
        )
        // 带首尾空白
        XCTAssertEqual(
            AppLauncher.webURL(fromRemote: "  git@github.com:user/repo.git  ")?.absoluteString,
            "https://github.com/user/repo"
        )
        // scp 语法无 .git
        XCTAssertEqual(
            AppLauncher.webURL(fromRemote: "git@github.com:user/repo")?.absoluteString,
            "https://github.com/user/repo"
        )
        // 空字符串返回 nil
        XCTAssertNil(AppLauncher.webURL(fromRemote: ""))
    }

    func testIsInstalledForKnownSystemApps() {
        // Finder / Terminal 在 macOS 上必然安装。
        XCTAssertTrue(AppLauncher.isInstalled(.finder))
        XCTAssertTrue(AppLauncher.isInstalled(.terminal))
        XCTAssertTrue(AppLauncher.isInstalled(.remote))
    }

    func testApplicationURLForFinder() {
        // Finder 必然可解析。
        XCTAssertNotNil(AppLauncher.applicationURL(for: .finder))
    }

    func testRemoteWebURLForNonRepositoryReturnsNil() {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("gitok-notrepo-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        XCTAssertNil(AppLauncher.remoteWebURL(for: tmp))
    }
}
