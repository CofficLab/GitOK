import Foundation
import ProviderProjects
import XCTest
@testable import PluginProjects

/// 项目列表持久化的单元测试（GitOK issue #18 回归）。
///
/// 回归的行为：
/// - 写入不再发生在主线程上（后台队列 + 合并写入）；
/// - 防抖窗口内的多次变更只落盘一次；
/// - 公开的 `persist()` 仍是同步语义（调用后数据已在盘上）。
@MainActor
final class ProjectStoreWriterTests: XCTestCase {
    private var tempDir: URL!
    private var storeURL: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ProjectStoreWriterTests-\(UUID().uuidString)", isDirectory: true)
        storeURL = tempDir.appendingPathComponent("projects.json")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    // MARK: - Merging

    func testRapidWritesAreCoalescedIntoOne() async throws {
        let writer = ProjectStoreWriter(storeURL: storeURL, debounceInterval: 0.2)

        // 防抖窗口内连续安排 5 次写入。
        for index in 0..<5 {
            writer.schedule(
                ProjectStore(
                    projects: [Project(url: URL(fileURLWithPath: "/tmp/Repo\(index)"))],
                    currentProjectID: nil
                )
            )
        }

        // 防抖窗口内不应已经写盘。
        XCTAssertFalse(
            FileManager.default.fileExists(atPath: storeURL.path),
            "防抖窗口内不应落盘"
        )

        // 等待防抖窗口结束后落盘。
        let deadline = Date().addingTimeInterval(2)
        while Date() < deadline,
              !FileManager.default.fileExists(atPath: storeURL.path) {
            try await Task.sleep(nanoseconds: 20_000_000)
        }

        XCTAssertTrue(FileManager.default.fileExists(atPath: storeURL.path))
        let data = try Data(contentsOf: storeURL)
        let decoded = try JSONDecoder().decode(ProjectStore.self, from: data)
        XCTAssertEqual(
            decoded.projects.map(\.title),
            ["Repo4"],
            "合并写入应保留最后一次状态"
        )
    }

    func testFlushBlockingWritesImmediately() throws {
        let writer = ProjectStoreWriter(storeURL: storeURL, debounceInterval: 10)

        writer.schedule(
            ProjectStore(
                projects: [Project(url: URL(fileURLWithPath: "/tmp/RepoA"))],
                currentProjectID: nil
            )
        )

        writer.flushBlocking()

        XCTAssertTrue(FileManager.default.fileExists(atPath: storeURL.path))
        let data = try Data(contentsOf: storeURL)
        let decoded = try JSONDecoder().decode(ProjectStore.self, from: data)
        XCTAssertEqual(decoded.projects.map(\.title), ["RepoA"])
    }

    func testCancelPendingDropsScheduledWrite() async throws {
        let writer = ProjectStoreWriter(storeURL: storeURL, debounceInterval: 0.1)
        writer.schedule(
            ProjectStore(
                projects: [Project(url: URL(fileURLWithPath: "/tmp/RepoA"))],
                currentProjectID: nil
            )
        )
        writer.cancelPending()

        try await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertFalse(
            FileManager.default.fileExists(atPath: storeURL.path),
            "被取消的写入不应落盘"
        )
    }

    // MARK: - Manager Integration

    func testManagerPersistIsSynchronous() throws {
        let manager = ProjectManager(storeURL: storeURL)
        manager.addProject(at: URL(fileURLWithPath: "/tmp/RepoA"))

        // persist() 返回后数据必须已经在盘上。
        manager.persist()
        XCTAssertTrue(FileManager.default.fileExists(atPath: storeURL.path))
        let data = try Data(contentsOf: storeURL)
        let decoded = try JSONDecoder().decode(ProjectStore.self, from: data)
        XCTAssertEqual(decoded.projects.map(\.title), ["RepoA"])
    }

    func testManagerMutationDoesNotWriteSynchronously() throws {
        let manager = ProjectManager(storeURL: storeURL)
        manager.addProject(at: URL(fileURLWithPath: "/tmp/RepoA"))

        // 内部变更走合并写入，不在主线程上同步落盘。
        XCTAssertFalse(
            FileManager.default.fileExists(atPath: storeURL.path),
            "变更本身不应同步写盘"
        )

        // 但冲刷后数据一定在盘上。
        manager.flushPersistence()
        XCTAssertTrue(FileManager.default.fileExists(atPath: storeURL.path))
    }

    func testManagerChangesArePersistedAfterFlush() throws {
        let manager = ProjectManager(storeURL: storeURL)
        manager.addProject(at: URL(fileURLWithPath: "/tmp/RepoA"))
        manager.flushPersistence()

        let reloaded = ProjectManager(storeURL: storeURL)
        XCTAssertEqual(reloaded.projects.map(\.title), ["RepoA"])
    }

    func testNewManagerSeesPendingWritesFromAnotherInstance() throws {
        let first = ProjectManager(storeURL: storeURL)
        first.addProject(at: URL(fileURLWithPath: "/tmp/RepoA"))

        // 新实例读盘前会先把挂起的写入冲刷出去，因此能看到刚才的变更。
        let second = ProjectManager(storeURL: storeURL)
        XCTAssertEqual(second.projects.map(\.title), ["RepoA"])
    }
}
