import Foundation
import Darwin

/// 可安全跨任务传递的 Git 子进程取消句柄。
public final class GitProcessCancellation: @unchecked Sendable {
    private let lock = NSLock()
    private var process: Process?
    private var cancelled = false
    private var finished = false

    public init() {}

    public var isCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return cancelled
    }

    public func cancel() {
        lock.lock()
        guard !finished else {
            lock.unlock()
            return
        }
        cancelled = true
        let process = self.process
        lock.unlock()

        if process?.isRunning == true {
            process?.terminate()
        }
    }

    fileprivate func attach(_ process: Process) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        self.process = process
        return cancelled
    }

    fileprivate func finish(_ process: Process) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if self.process === process {
            self.process = nil
        }
        finished = true
        return cancelled
    }
}

/// 统一 git CLI 执行入口（供 KitGit 内各加载器复用）。
///
/// 当前阶段使用系统自带 git（macOS 预装）以零第三方依赖读取 git 数据；
/// 后续若迁移到 LibGit2（旧版方案），只需替换本执行器。
public enum GitProcessRunner {
    private final class DataBox: @unchecked Sendable {
        var value = Data()
    }

    private final class TimeoutState: @unchecked Sendable {
        private let lock = NSLock()
        private var didTimeout = false

        func markTimedOut() {
            lock.lock()
            didTimeout = true
            lock.unlock()
        }

        var hasTimedOut: Bool {
            lock.lock()
            defer { lock.unlock() }
            return didTimeout
        }
    }

    public enum Error: Swift.Error, LocalizedError {
        case gitUnavailable(String)
        case gitFailed(String)
        case timedOut(String)

        public var errorDescription: String? {
            switch self {
            case .gitUnavailable(let message):
                String(format: LumiPluginLocalization.string("Git unavailable: %@", bundle: .module), message)
            case .gitFailed(let message):
                message
            case .timedOut(let command):
                String(format: LumiPluginLocalization.string("Git command timed out: %@", bundle: .module), command)
            }
        }
    }

    public static var isAvailable: Bool {
        gitExecutableURL != nil
    }

    private static var gitExecutableURL: URL? {
        let candidates = [
            "/usr/bin/git",
            "/opt/homebrew/bin/git",
            "/usr/local/bin/git",
            "/usr/local/git/bin/git",
        ]
        if let bundled = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) {
            return URL(fileURLWithPath: bundled)
        }

        let pathEntries = ProcessInfo.processInfo.environment["PATH"]?.split(separator: ":") ?? []
        return pathEntries
            .map { String($0) }
            .map { URL(fileURLWithPath: $0).appendingPathComponent("git") }
            .first(where: { FileManager.default.isExecutableFile(atPath: $0.path) })
    }

    /// 在指定仓库目录执行 git 命令并返回标准输出（UTF-8）。
    /// 非零退出码抛 `gitFailed`，输出与 stderr 一并带出。
    ///
    /// `successExitCodes` 用于容忍"有差异即返回非零"的命令（如
    /// `git diff --no-index` 有差异时退出码为 1，属正常结果）。
    public static func run(
        _ arguments: [String],
        in repository: URL,
        successExitCodes: Set<Int32> = [0],
        timeout: TimeInterval? = nil
    ) throws -> String {
        var outputData = Data()
        try stream(
            arguments,
            in: repository,
            successExitCodes: successExitCodes,
            timeout: timeout
        ) { data in
            outputData.append(data)
            return true
        }
        return Self.decode(outputData)
    }

    /// 流式读取标准输出。回调返回 `false` 时会尽早停止子进程，适合只需要
    /// 某一页结果的 Git 查询；整个过程中不会把标准输出拼成一个大字符串。
    public static func stream(
        _ arguments: [String],
        in repository: URL,
        successExitCodes: Set<Int32> = [0],
        chunkSize: Int = 64 * 1024,
        cancellation: GitProcessCancellation? = nil,
        timeout: TimeInterval? = nil,
        onOutput: (Data) -> Bool,
        onErrorOutput: (@Sendable (Data) -> Void)? = nil
    ) throws {
        let process = Process()
        guard let gitExecutableURL else {
            throw Error.gitUnavailable("git executable not found")
        }
        process.executableURL = gitExecutableURL
        process.arguments = arguments
        process.currentDirectoryURL = repository

        let cancelBeforeRun = cancellation?.attach(process) ?? false

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
        } catch {
            _ = cancellation?.finish(process)
            throw Error.gitUnavailable(error.localizedDescription)
        }

        if cancelBeforeRun {
            process.terminate()
        }

        let timeoutState = timeout.map { _ in TimeoutState() }
        let timeoutWorkItem: DispatchWorkItem?
        if let timeout, timeout >= 0 {
            let workItem = DispatchWorkItem {
                guard process.isRunning else { return }
                timeoutState?.markTimedOut()
                process.terminate()
                // A Git process blocked in a filesystem call may not handle
                // SIGTERM promptly. Escalate only this timed-out child after
                // a short grace period so callers never wait indefinitely.
                DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 1) {
                    if process.isRunning {
                        Darwin.kill(process.processIdentifier, SIGKILL)
                    }
                }
            }
            timeoutWorkItem = workItem
            DispatchQueue.global(qos: .utility).asyncAfter(
                deadline: .now() + timeout,
                execute: workItem
            )
        } else {
            timeoutWorkItem = nil
        }

        // stderr 必须与 stdout 并行消费，否则 git 在输出大量警告时可能因为
        // stderr 管道写满而无法继续，导致 stdout 读取永远等不到结束。
        let errorGroup = DispatchGroup()
        let errorData = DataBox()
        errorGroup.enter()
        // 不要把排水任务放到调用方可能正在占满的全局队列中。
        // Git 查询通常从 utility 任务启动；如果排水任务也进入 utility，
        // 所有 worker 都可能阻塞在下面的 errorGroup.wait()，导致排水任务永远
        // 无法获得 worker，最终表现为所有 Git 加载器无限 loading。
        let errorThread = Thread {
            while true {
                let data = errorPipe.fileHandleForReading.readData(ofLength: max(chunkSize, 1))
                if data.isEmpty { break }
                errorData.value.append(data)
                onErrorOutput?(data)
            }
            errorGroup.leave()
        }
        // The caller may be a user-initiated task and waits for this thread
        // below. Match that QoS so the wait cannot be reported as a priority
        // inversion against a default-priority stderr reader.
        errorThread.qualityOfService = .userInitiated
        errorThread.start()

        var shouldStop = false
        while true {
            let data = outputPipe.fileHandleForReading.readData(ofLength: max(chunkSize, 1))
            if data.isEmpty { break }
            if !onOutput(data) {
                shouldStop = true
                process.terminate()
                break
            }
        }

        process.waitUntilExit()
        let wasCancelled = cancellation?.finish(process) ?? false
        timeoutWorkItem?.cancel()
        let didTimeout = timeoutState?.hasTimedOut ?? false
        // 终止早停后仍然清空剩余管道，避免文件描述符和子进程资源泄漏。
        _ = outputPipe.fileHandleForReading.readDataToEndOfFile()
        errorGroup.wait()

        if wasCancelled {
            throw CancellationError()
        }

        if didTimeout {
            throw Error.timedOut(arguments.joined(separator: " "))
        }

        guard shouldStop || successExitCodes.contains(process.terminationStatus) else {
            let message = Self.decode(errorData.value, fallback: "unknown error")
            throw Error.gitFailed(message)
        }
    }

    /// 容错解码 git 输出：优先 UTF-8（无损保留）；失败则回退 GB18030
    /// （覆盖 GBK/GB2312，国内仓库常见编码）；仍失败则 lossy 解码
    /// （非法字节替换为 U+FFFD，保证不吞掉整段 diff）。
    /// 修复：文件内容为非 UTF-8 时 `String(data:, encoding: .utf8)`
    /// 返回 nil，导致 diff 被判定为 "No Text Diff"。
    private static func decode(_ data: Data, fallback: String = "") -> String {
        if data.isEmpty { return fallback }
        if let utf8 = String(data: data, encoding: .utf8) {
            return utf8
        }
        let gb18030 = String.Encoding(
            rawValue: CFStringConvertEncodingToNSStringEncoding(
                CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)
            )
        )
        if let gb = String(data: data, encoding: gb18030) {
            return gb
        }
        let lossy = String(decoding: data, as: UTF8.self)
        return lossy.isEmpty ? fallback : lossy
    }
}
