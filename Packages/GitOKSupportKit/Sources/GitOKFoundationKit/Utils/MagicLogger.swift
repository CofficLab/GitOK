import Combine
import OSLog
import SwiftUI

/// 日志管理器，用于收集和展示日志
public class MagicLogger: ObservableObject, @unchecked Sendable {
    /// 单例模式
    public static let shared = MagicLogger()

    /// 存储的日志条目
    @Published private(set) var logs: [MagicLogEntry] = []

    /// 应用名称
    @Published public var app: String

    /// 最大日志数量
    private let maxLogCount = 300
    private let maxLogMessageLength = 2_000

    /// 用于同步访问的锁
    private let lock = NSLock()
    private var pendingLogs: [MagicLogEntry] = []
    private var isFlushScheduled = false

    public init(app: String = "Default") {
        self.app = app
    }

    // MARK: - Static Methods

    /// 记录一条日志
    /// - Parameters:
    ///   - message: 日志消息
    ///   - level: 日志级别
    ///   - caller: 日志发生的位置
    public static func log(_ message: String, level: MagicLogEntry.Level, caller: String = #fileID, line: Int = #line) {
        shared.log(message, level: level, caller: fileName(from: caller), line: line)
    }

    private static func fileName(from file: String) -> String {
        file.components(separatedBy: "/").last?.components(separatedBy: ".").first ?? file
    }

    // ... existing static methods ...

    // MARK: - Public Methods

    /// 记录一条日志
    /// - Parameters:
    ///   - message: 日志消息
    ///   - level: 日志级别
    ///   - caller: 日志发生的位置
    public func log(_ message: String, level: MagicLogEntry.Level, caller: String = #fileID, line: Int = #line) {
        addLog(message, level: level, caller: Self.fileName(from: caller), line: line)
    }

    /// 添加一条信息日志
    /// - Parameters:
    ///   - message: 日志消息
    ///   - caller: 日志发生的位置
    public static func info(_ message: String, caller: String = #fileID, line: Int = #line) {
        shared.info(message, caller: fileName(from: caller), line: line)
    }

    /// 添加一条警告日志
    /// - Parameters:
    ///   - message: 日志消息
    ///   - caller: 日志发生的位置
    public static func warning(_ message: String, caller: String = #fileID, line: Int = #line) {
        shared.warning(message, caller: fileName(from: caller), line: line)
    }

    /// 添加一条错误日志
    /// - Parameters:
    ///   - message: 日志消息
    ///   - caller: 日志发生的位置
    public static func error(_ message: String, caller: String = #fileID, line: Int = #line) {
        shared.error(message, caller: fileName(from: caller), line: line)
    }

    /// 添加一条调试日志
    /// - Parameters:
    ///   - message: 日志消息
    ///   - caller: 日志发生的位置
    public static func debug(_ message: String, caller: String = #fileID, line: Int = #line) {
        shared.debug(message, caller: fileName(from: caller), line: line)
    }

    /// 清空所有日志
    public static func clearLogs() {
        shared.clearLogs()
    }

    // MARK: - Public Methods

    /// 添加一条信息日志
    /// - Parameters:
    ///   - message: 日志消息
    ///   - caller: 日志发生的位置
    public func info(_ message: String, caller: String = #fileID, line: Int = #line) {
        addLog(message, level: .info, caller: Self.fileName(from: caller), line: line)
    }

    /// 添加一条警告日志
    /// - Parameters:
    ///   - message: 日志消息
    ///   - caller: 日志发生的位置
    public func warning(_ message: String, caller: String = #fileID, line: Int = #line) {
        addLog(message, level: .warning, caller: Self.fileName(from: caller), line: line)
    }

    /// 添加一条错误日志
    /// - Parameters:
    ///   - message: 日志消息
    ///   - caller: 日志发生的位置
    public func error(_ message: String, caller: String = #fileID, line: Int = #line) {
        addLog(message, level: .error, caller: Self.fileName(from: caller), line: line)
    }

    /// 添加一条调试日志
    /// - Parameters:
    ///   - message: 日志消息
    ///   - caller: 日志发生的位置
    public func debug(_ message: String, caller: String = #fileID, line: Int = #line) {
        addLog(message, level: .debug, caller: Self.fileName(from: caller), line: line)
    }

    /// 清空所有日志
    public func clearLogs() {
        lock.lock()
        pendingLogs.removeAll()
        lock.unlock()
        DispatchQueue.main.async {
            self.logs.removeAll()
        }
    }

    // MARK: - Private Methods

    private func addLog(_ message: String, level: MagicLogEntry.Level, caller: String, line: Int?) {
        let storedMessage = trimmedMessage(message)
        let entry = MagicLogEntry(message: storedMessage, level: level, caller: caller, line: line)
        let shouldScheduleFlush: Bool

        lock.lock()
        pendingLogs.append(entry)
        shouldScheduleFlush = isFlushScheduled == false
        isFlushScheduled = true
        lock.unlock()

        if shouldScheduleFlush {
            DispatchQueue.main.async {
                self.flushPendingLogs()
            }
        }

        var level = OSLogType.debug

        switch entry.level {
        case .info:
            level = .info
        case .warning:
            level = .info
        case .error:
            level = .error
        case .debug:
            level = .debug
        }

        var title = "\(entry.caller.withContextEmoji):\(entry.line ?? 0)"
        title = title.padding(toLength: 30, withPad: " ", startingAt: 0)
        
        os_log(level, "\(Thread.currentQosDescription) | \(title) | \(entry.originalMessage.withContextEmoji)")
    }

    private func flushPendingLogs() {
        let entries: [MagicLogEntry]

        lock.lock()
        entries = pendingLogs
        pendingLogs.removeAll(keepingCapacity: true)
        isFlushScheduled = false
        lock.unlock()

        guard entries.isEmpty == false else { return }

        logs.append(contentsOf: entries)
        if logs.count > maxLogCount {
            logs.removeFirst(logs.count - maxLogCount)
        }
    }

    private func trimmedMessage(_ message: String) -> String {
        guard message.count > maxLogMessageLength else {
            return message
        }

        return String(message.prefix(maxLogMessageLength)) + "\n... log message truncated ..."
    }
}
