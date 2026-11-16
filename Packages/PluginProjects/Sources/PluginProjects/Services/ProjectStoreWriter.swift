import Foundation
import os
import ProviderProjects

/// 项目列表的磁盘存储容器。
///
/// 格式与历史版本保持一致：同时兼容「容器格式」（含 `currentProjectID`）
/// 与「旧版纯数组格式」。
struct ProjectStore: Codable, Sendable {
    var projects: [Project]
    var currentProjectID: UUID?
}

/// 项目列表持久化写入器：后台写入 + 合并短时间内的重复写入。
///
/// 解决的问题（GitOK issue #18）：
/// 此前每次项目变更（**包括仅仅打开一个项目**）都会在主线程上
/// 重新编码整份项目数组并原子写盘。项目上千时，这既是可观的 CPU 开销，
/// 也是可观的磁盘写入量。
///
/// 本写入器的行为：
/// - **后台写入**：编码与写盘都不占用主线程。
/// - **合并写入**：防抖窗口内的多次变更只落盘一次
///   （例如拖拽排序过程中的连续 `moveProject`）。
/// - **可同步冲刷**：`flushBlocking()` 等待挂起的写入完成，
///   供「从磁盘重新加载」等必须读到最新状态的时机使用。
///
/// 写入器按存储路径**共享**（`writer(for:)`）：同一路径上的多个
/// `ProjectManager` 实例（测试里会新建实例重载数据）共用一个写入队列，
/// 因此新实例读盘前能先把上一个实例挂起的写入冲刷出去。
final class ProjectStoreWriter: @unchecked Sendable {
    /// 合并写入的防抖窗口（秒）。
    static let defaultDebounceInterval: TimeInterval = 0.12

    private let logger = Logger(subsystem: "com.coffic.gitok.plugin.projects", category: "Projects")
    private let storeURL: URL
    private let lock = NSLock()
    private let queue: DispatchQueue
    private let debounceInterval: TimeInterval

    /// 待写入的最新状态。
    private var pending: ProjectStore?
    /// 是否已安排一次冲刷。
    private var scheduled = false

    // MARK: - Shared Registry

    private static let registryLock = NSLock()
    /// 共享写入器表；所有读写都在 `registryLock` 保护下进行。
    private nonisolated(unsafe) static var registry: [String: ProjectStoreWriter] = [:]

    /// 取得（并在必要时创建）指定存储路径的写入器。
    static func writer(for storeURL: URL) -> ProjectStoreWriter {
        let key = storeURL.standardizedFileURL.path
        registryLock.lock()
        defer { registryLock.unlock() }
        if let existing = registry[key] {
            return existing
        }
        let created = ProjectStoreWriter(storeURL: storeURL)
        registry[key] = created
        return created
    }

    init(
        storeURL: URL,
        debounceInterval: TimeInterval = ProjectStoreWriter.defaultDebounceInterval
    ) {
        self.storeURL = storeURL
        self.debounceInterval = max(0, debounceInterval)
        self.queue = DispatchQueue(
            label: "com.coffic.gitok.plugin.projects.store-writer",
            qos: .utility
        )
    }

    // MARK: - Scheduling

    /// 安排一次写入；防抖窗口内的重复调用只保留最新状态。
    func schedule(_ store: ProjectStore) {
        lock.lock()
        pending = store
        let needsSchedule = !scheduled
        scheduled = true
        lock.unlock()

        guard needsSchedule else { return }
        queue.asyncAfter(deadline: .now() + debounceInterval) { [weak self] in
            self?.drain()
        }
    }

    /// 丢弃挂起的写入（例如重新从磁盘加载前）。
    func cancelPending() {
        lock.lock()
        pending = nil
        lock.unlock()
    }

    /// 立即落盘并等待完成（阻塞调用线程）。
    ///
    /// 写入在写入队列上串行执行，因此与后台写入保持先后顺序。
    func flushBlocking() {
        queue.sync { drainNow() }
    }

    // MARK: - Writing

    /// 防抖窗口结束后取出最新状态并写入。
    private func drain() {
        drainNow()
    }

    private func drainNow() {
        lock.lock()
        let store = pending
        pending = nil
        scheduled = false
        lock.unlock()

        guard let store else { return }
        write(store)
    }

    private func write(_ store: ProjectStore) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(store)
            try data.write(to: storeURL, options: .atomic)
        } catch {
            logger.error("failed to persist projects: \(error.localizedDescription, privacy: .public)")
        }
    }
}
