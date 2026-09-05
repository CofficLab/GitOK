import CoreServices
import Foundation

/// `.git` 目录的 FSEventStream 监听器。
///
/// 用 macOS 的 `FSEventStream` 监听指定 git 目录内的任意文件变化（HEAD /
/// index / stash / refs 等），触发时通过 `onChange` 回调通知上层。回调统一
/// 派发到 MainActor，上层无需处理线程切换。
///
/// 对齐旧版 `GitDirectoryWatcher`：
/// - 用 `kFSEventStreamCreateFlagFileEvents` + `kFSEventStreamCreateFlagNoDefer`
///   精确到文件级别事件；
/// - 0.5 秒延迟窗口合并突发事件；
/// - 派发到 `utility` 队列，避免阻塞主线程；
/// - `onChange` 在 MainActor 上执行。
///
/// 本类只负责"目录变了"的粗粒度通知；细分维度（HEAD / index / stash / refs
/// 哪个变了）由上层 `GitRepositoryWatchProvider` 通过对比快照判断。
///
/// - Note: 标记 `@unchecked Sendable` 是因为 FSEventStream 回调从 utility
///   队列跨 actor 边界引用 `self`；调用方保证 `onChange` 只在 MainActor 调用、
///   `stop()` 只在 MainActor 调用、`stream` 读写由调用方串行化，因此跨队列
///   引用是安全的。
final class GitDirectoryWatcher: @unchecked Sendable {
    private let url: URL
    private let onChange: @MainActor () -> Void
    private var stream: FSEventStreamRef?

    /// 创建一个监听器并立即启动。
    ///
    /// - Throws: 流创建失败时抛出 `GitDirectoryWatcherError.streamCreationFailed`。
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

    private enum GitDirectoryWatcherError: Error {
        case streamCreationFailed(String)
    }

    private func start() throws {
        // 桥接上下文：把 `self` 通过 `info` 指针传进 FSEventStream 回调。
        // 用 `passUnretained` 因为 `self` 在 stop/deinit 前始终存活；
        // 回调里用 `takeUnretainedValue` 取回。
        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let callback: FSEventStreamCallback = { _, info, _, _, _, _ in
            guard let info else { return }
            // 回调在 FSEventStream 的派发队列（utility）上执行；
            // 派发到 MainActor 再调用 onChange，保证上层状态修改线程安全。
            let watcher = Unmanaged<GitDirectoryWatcher>.fromOpaque(info).takeUnretainedValue()
            Task { @MainActor in
                watcher.onChange()
            }
        }

        let paths = [url.path] as CFArray
        let flags = FSEventStreamCreateFlags(
            kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagNoDefer
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
            throw GitDirectoryWatcherError.streamCreationFailed(url.path)
        }

        self.stream = stream
        FSEventStreamSetDispatchQueue(stream, DispatchQueue.global(qos: .utility))
        FSEventStreamStart(stream)
    }
}
