import CoreServices
import Foundation

/// 项目工作区（仓库根目录）的 FSEventStream 监听器。
///
/// 用 macOS 的 `FSEventStream` 监听项目根目录内的文件变化（新增 / 修改 / 删除），
/// 触发时通过 `onChange` 回调通知上层。回调统一派发到 MainActor。
///
/// 与 `GitDirectoryWatcher` 的区别：
/// - `GitDirectoryWatcher` 监听 `.git` 目录，检测 git 内部状态变化；
/// - `WorkingTreeWatcher` 监听项目根目录，检测工作区文件变化。
///
/// 注意事项：
/// - 自动忽略 `.git`、`.build` 和 DerivedData 等仓库内部生成目录；
/// - 0.5 秒延迟窗口合并突发事件；
/// - 派发到 `utility` 队列，避免阻塞主线程；
/// - `onChange` 在 MainActor 上执行。
///
/// - Note: 标记 `@unchecked Sendable` 是因为 FSEventStream 回调从 utility
///   队列跨 actor 边界引用 `self`；调用方保证 `onChange` 只在 MainActor 调用、
///   `stop()` 只在 MainActor 调用、`stream` 读写由调用方串行化。
final class WorkingTreeWatcher: @unchecked Sendable {
    private let url: URL
    private let onChange: @MainActor () -> Void
    private var stream: FSEventStreamRef?

    /// 创建一个监听器并立即启动。
    ///
    /// - Throws: 流创建失败时抛出 `WorkingTreeWatcherError.streamCreationFailed`。
    init(url: URL, onChange: @escaping @MainActor () -> Void) throws {
        self.url = url
        self.onChange = onChange
        try start()
    }

    deinit {
        stop()
    }

    /// 停止监听并释放 FSEventStream 资源。可重复调用。
    func stop() {
        guard let stream else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        self.stream = nil
    }

    // MARK: - Private

    private enum WorkingTreeWatcherError: Error {
        case streamCreationFailed(String)
    }

    private func start() throws {
        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let callback: FSEventStreamCallback = { _, info, _, _, _, _ in
            guard let info else { return }
            let watcher = Unmanaged<WorkingTreeWatcher>.fromOpaque(info).takeUnretainedValue()
            Task { @MainActor in
                watcher.onChange()
            }
        }

        let paths = [url.path] as CFArray
        let flags = FSEventStreamCreateFlags(
            kFSEventStreamCreateFlagFileEvents |
            kFSEventStreamCreateFlagNoDefer |
            kFSEventStreamCreateFlagIgnoreSelf
        )

        guard let stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            callback,
            &context,
            paths,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.5,
            flags
        ) else {
            throw WorkingTreeWatcherError.streamCreationFailed(url.path)
        }

        self.stream = stream
        FSEventStreamSetExclusionPaths(stream, Self.excludedPaths(for: url) as CFArray)
        FSEventStreamSetDispatchQueue(stream, DispatchQueue.global(qos: .utility))
        FSEventStreamStart(stream)
    }

    /// 返回仓库内由 Git / 构建工具维护的目录，交给 FSEventStream 原生排除。
    static func excludedPaths(for repositoryURL: URL) -> [String] {
        let repository = repositoryURL.standardizedFileURL
        return [
            repository.appendingPathComponent(".git").path,
            repository.appendingPathComponent(".build").path,
            repository.appendingPathComponent("DerivedData").path,
        ]
    }
}
