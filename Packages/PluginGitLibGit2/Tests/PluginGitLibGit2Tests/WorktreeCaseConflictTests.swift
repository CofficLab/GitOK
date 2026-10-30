import Foundation
import KitGit
import LibGit2Swift
import Testing
@testable import PluginGitLibGit2

/// 复现「GitOK 显示 N 个未提交变更，但 `git status` 说工作区干净」。
///
/// 前提：仓库的 HEAD 与 index 中同时存在仅大小写不同的同名条目（如
/// `SUPPLIER.php` 与 `Supplier.php`），且仓库位于**大小写不敏感**的文件系统
/// 上（macOS APFS 默认）。磁盘上只存在一份文件。
///
/// 在这种仓库上：
/// - `git status`（CLI）认为工作区干净；
/// - libgit2 却把条目报成 `[ D]`（工作区已删除），
///   于是 GitOK 的变更列表多出一批并不存在的「未暂存」条目。
///
/// 两者结论不一致，而 GitOK 生产链路只用 LibGit2 后端
/// （`GitBackendCatalog.all == [libGit2]`），因此 UI 直接暴露了这个偏差。
///
/// 触发条件已精确定位：**index 中同时存在两个仅大小写不同的条目**。
/// 只有一个变体时（无论大小写）libgit2 与 CLI 结论一致。
@Suite("大小写冲突仓库的工作区状态")
struct WorktreeCaseConflictTests {
    /// 构造一个 HEAD / index 中同时存在大小写变体、磁盘上只留一份文件的仓库。
    ///
    /// 与真实场景一致：两个变体在**同一个提交**里入库，因此 index 与 HEAD
    /// 完全同步，CLI 判定工作区干净。
    private func makeRepository(
        uppercaseName: String,
        camelName: String
    ) throws -> (repository: URL, cleanup: () -> Void) {
        let repository = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-case-conflict-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: repository, withIntermediateDirectories: true)

        _ = try GitProcessRunner.run(["init", "-q"], in: repository)
        _ = try GitProcessRunner.run(["config", "user.email", "test@example.com"], in: repository)
        _ = try GitProcessRunner.run(["config", "user.name", "GitOK Test"], in: repository)
        // macOS 默认文件系统不区分大小写；显式打开该选项以对齐真实场景。
        _ = try GitProcessRunner.run(["config", "core.ignorecase", "true"], in: repository)

        let content = Data("<?php\n// supplier\n".utf8)
        try content.write(to: repository.appendingPathComponent(camelName))
        _ = try GitProcessRunner.run(["add", "-A"], in: repository)
        _ = try GitProcessRunner.run(["commit", "-qm", "initial"], in: repository)

        // 往 index 里塞入大写变体条目（blob 与驼峰变体相同），并提交，
        // 使 HEAD 与 index 保持一致 —— 这正是 CLI 判定「工作区干净」的前提。
        let blob = try GitProcessRunner.run(["hash-object", camelName], in: repository)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        _ = try GitProcessRunner.run(
            ["update-index", "--add", "--cacheinfo", "100644,\(blob),\(uppercaseName)"],
            in: repository
        )
        _ = try GitProcessRunner.run(["commit", "-qm", "add uppercase variant"], in: repository)

        return (repository, { try? FileManager.default.removeItem(at: repository) })
    }

    @Test("CLI 认为工作区干净时，LibGit2 不应该报出未暂存删除")
    func libGit2AgreesWithCLIOnCleanWorktree() throws {
        let (repository, cleanup) = try makeRepository(
            uppercaseName: "SUPPLIER.php",
            camelName: "Supplier.php"
        )
        defer { cleanup() }

        // 前提校验：CLI 认为工作区是干净的。
        let cliStatus = try GitStatusLoader.loadStatus(in: repository)
        #expect(cliStatus.isClean, "前提失败：CLI 应认为工作区干净")

        // 被测行为：libgit2 后端必须与 CLI 结论一致。
        let backend = GitLibGit2Backend()
        let entries = try backend.loadEntries(in: repository)

        #expect(
            entries.isEmpty,
            """
            libgit2 与 git CLI 结论不一致：CLI 说工作区干净，libgit2 却报出 \
            \(entries.count) 条变更：\(entries.map { "\($0.path)[\($0.stagedStatus)\($0.worktreeStatus)]" })
            """
        )
    }

    @Test("大小写冲突条目不应被标记为未暂存删除")
    func caseConflictEntriesAreNotReportedAsDeleted() throws {
        let (repository, cleanup) = try makeRepository(
            uppercaseName: "SUPPLIER.php",
            camelName: "Supplier.php"
        )
        defer { cleanup() }

        let entries = try GitLibGit2Backend().loadEntries(in: repository)

        let deleted = entries.filter { $0.worktreeStatus == "D" }
        #expect(
            deleted.isEmpty,
            "大写变体在磁盘上并不存在，不应被报成删除：\(deleted.map(\.path))"
        )
    }

    @Test("工作区摘要的变更数与 CLI 一致")
    func worktreeStatusChangeCountMatchesCLI() throws {
        let (repository, cleanup) = try makeRepository(
            uppercaseName: "SUPPLIER.php",
            camelName: "Supplier.php"
        )
        defer { cleanup() }

        let cliStatus = try GitStatusLoader.loadStatus(in: repository)
        let backendStatus = try GitLibGit2Backend().loadStatus(in: repository)

        #expect(
            backendStatus.changeCount == cliStatus.changeCount,
            "变更条数不一致：CLI=\(cliStatus.changeCount) libgit2=\(backendStatus.changeCount)"
        )
    }

    @Test("真实供应商仓库形态：4 对大小写变体只应报告 0 条变更")
    func supplierRepositoryShapeReportsNoChanges() throws {
        let pairs = [
            ("BANGCHONG.php", "BangChong.php"),
            ("JIEPAI.php", "JiePai.php"),
            ("SHOUKALA.php", "ShouKaLa.php"),
            ("THINKLAND.php", "ThinkLand.php"),
        ]
        let repository = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-case-supplier-\(UUID().uuidString)", isDirectory: true)
        let supplierDirectory = repository.appendingPathComponent("app/Service/Supplier")
        try FileManager.default.createDirectory(
            at: supplierDirectory,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: repository) }

        _ = try GitProcessRunner.run(["init", "-q"], in: repository)
        _ = try GitProcessRunner.run(["config", "user.email", "test@example.com"], in: repository)
        _ = try GitProcessRunner.run(["config", "user.name", "GitOK Test"], in: repository)
        _ = try GitProcessRunner.run(["config", "core.ignorecase", "true"], in: repository)

        let content = Data("<?php\n".utf8)
        for (_, camelName) in pairs {
            try content.write(to: supplierDirectory.appendingPathComponent(camelName))
        }
        _ = try GitProcessRunner.run(["add", "-A"], in: repository)
        _ = try GitProcessRunner.run(["commit", "-qm", "initial"], in: repository)

        // 4 个大写变体入库（与驼峰变体 blob 相同），并提交。
        for (uppercaseName, camelName) in pairs {
            let blob = try GitProcessRunner.run(
                ["hash-object", "app/Service/Supplier/\(camelName)"],
                in: repository
            ).trimmingCharacters(in: .whitespacesAndNewlines)
            _ = try GitProcessRunner.run(
                [
                    "update-index", "--add", "--cacheinfo",
                    "100644,\(blob),app/Service/Supplier/\(uppercaseName)",
                ],
                in: repository
            )
        }
        _ = try GitProcessRunner.run(["commit", "-qm", "add uppercase variants"], in: repository)

        let cliStatus = try GitStatusLoader.loadStatus(in: repository)
        #expect(cliStatus.isClean, "前提失败：CLI 应认为工作区干净")

        let entries = try GitLibGit2Backend().loadEntries(in: repository)
        #expect(
            entries.isEmpty,
            """
            4 对大小写变体导致 libgit2 报出 \(entries.count) 条虚假变更：\
            \(entries.map { "\($0.path)[\($0.stagedStatus)\($0.worktreeStatus)]" })
            """
        )
    }
}
