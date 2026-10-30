import Foundation
import KitGit
import Testing
@testable import KitGit

/// `GitCaseConflictResolver` 的纯逻辑测试。
///
/// 这些规则决定了 libgit2 报出的「工作区已删除」是**真实删除**还是
/// **大小写冲突造成的假删除**。误伤真实删除会丢数据，因此必须严格覆盖。
@Suite("大小写冲突识别")
struct GitCaseConflictResolverTests {
    @Test("仅大小写不同的路径会被归为同一组")
    func caseInsensitiveGroupsDetectConflict() {
        let groups = GitCaseConflictResolver.caseInsensitiveGroups(in: [
            "app/Service/Supplier/BANGCHONG.php",
            "app/Service/Supplier/BangChong.php",
            "app/Service/Supplier/Base.php",
        ])

        #expect(groups.count == 1)
        #expect(
            groups["app/service/supplier/bangchong.php"]?.count == 2
        )
    }

    @Test("没有大小写冲突时返回空分组")
    func noConflictForDistinctPaths() {
        #expect(
            GitCaseConflictResolver.caseInsensitiveGroups(in: [
                "a/Base.php",
                "b/Base.php",
            ]).isEmpty
        )
        #expect(
            GitCaseConflictResolver.hasCaseConflict(in: ["a/Base.php", "b/Base.php"]) == false
        )
    }

    @Test("不同目录下同名文件不算冲突")
    func sameNameInDifferentDirectoriesIsNotConflict() {
        #expect(
            GitCaseConflictResolver.hasCaseConflict(in: [
                "app/Service/Supplier/JD.php",
                "app/Model/JD.php",
            ]) == false
        )
    }

    @Test("索引中没有大小写冲突时，假删除条目被原样保留")
    func keepsEntriesWhenNoConflict() {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-resolver-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let entries = [
            GitCaseConflictResolver.Entry(path: "a.txt", stagedStatus: " ", worktreeStatus: "D"),
        ]

        let result = GitCaseConflictResolver.removingFalseDeletions(
            entries: entries,
            indexPaths: ["a.txt"],
            worktreeRoot: root
        )

        #expect(result == entries, "没有冲突时不得剔除任何条目")
    }

    @Test("报成删除但文件在磁盘上存在时，条目被剔除")
    func removesFalseDeletionWhenFileExists() {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-resolver-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try? Data("content\n".utf8).write(to: root.appendingPathComponent("Supplier.php"))

        let entries = [
            GitCaseConflictResolver.Entry(
                path: "Supplier.php",
                stagedStatus: " ",
                worktreeStatus: "D"
            ),
        ]

        let result = GitCaseConflictResolver.removingFalseDeletions(
            entries: entries,
            indexPaths: ["SUPPLIER.php", "Supplier.php"],
            worktreeRoot: root
        )

        #expect(result.isEmpty, "文件确实在磁盘上，不该报成删除")
    }

    @Test("真实删除（文件不在磁盘上）被保留")
    func keepsRealDeletion() {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-resolver-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let entries = [
            GitCaseConflictResolver.Entry(
                path: "Supplier.php",
                stagedStatus: " ",
                worktreeStatus: "D"
            ),
        ]

        let result = GitCaseConflictResolver.removingFalseDeletions(
            entries: entries,
            indexPaths: ["SUPPLIER.php", "Supplier.php"],
            worktreeRoot: root
        )

        #expect(result == entries, "文件真的不在磁盘上，必须保留删除条目")
    }

    @Test("非删除条目不受影响")
    func nonDeletionEntriesUntouched() {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-resolver-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let entries = [
            GitCaseConflictResolver.Entry(path: "a.txt", stagedStatus: " ", worktreeStatus: "M"),
            GitCaseConflictResolver.Entry(path: "b.txt", stagedStatus: "?", worktreeStatus: "?"),
            GitCaseConflictResolver.Entry(path: "c.txt", stagedStatus: "D", worktreeStatus: " "),
        ]

        let result = GitCaseConflictResolver.removingFalseDeletions(
            entries: entries,
            indexPaths: ["A.TXT", "a.txt", "b.txt", "c.txt"],
            worktreeRoot: root
        )

        #expect(result == entries)
    }
}
