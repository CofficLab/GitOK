import Foundation
import OSLog
import SwiftUI

/// 性能监控工具类
public class MagicPerformance {
    /// 日志记录器
    internal static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "GitOKSupportKit",
        category: "Performance"
    )
    
    /// 测量代码块执行时间
    /// - Parameters:
    ///   - operation: 操作名称
    ///   - file: 调用文件名（默认）
    ///   - function: 调用函数名（默认）
    ///   - line: 调用行号（默认）
    ///   - action: 要执行的代码块
    /// - Returns: 执行时间（秒）
    @discardableResult
    public static func measure(
        _ operation: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        action: () -> Void
    ) -> TimeInterval {
        let start = CFAbsoluteTimeGetCurrent()
        action()
        let diff = CFAbsoluteTimeGetCurrent() - start
        
        logger.debug("⏱️ [\(operation)] 耗时: \(String(format: "%.4f", diff))s [\(file):\(line)]")
        return diff
    }
    
    /// 异步测量代码块执行时间
    /// - Parameters:
    ///   - operation: 操作名称
    ///   - file: 调用文件名（默认）
    ///   - function: 调用函数名（默认）
    ///   - line: 调用行号（默认）
    ///   - action: 要执行的异步代码块
    /// - Returns: 执行时间（秒）
    @discardableResult
    public static func measureAsync(
        _ operation: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        action: () async -> Void
    ) async -> TimeInterval {
        let start = CFAbsoluteTimeGetCurrent()
        await action()
        let diff = CFAbsoluteTimeGetCurrent() - start
        
        logger.debug("⏱️ [\(operation)] 异步耗时: \(String(format: "%.4f", diff))s [\(file):\(line)]")
        return diff
    }
    
    /// 记录内存使用情况
    /// - Parameters:
    ///   - tag: 标记名称
    ///   - file: 调用文件名（默认）
    ///   - function: 调用函数名（默认）
    ///   - line: 调用行号（默认）
    public static func logMemoryUsage(
        _ tag: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let usedMB = Double(info.resident_size) / 1024.0 / 1024.0
            logger.debug("📊 [\(tag)] 内存使用: \(String(format: "%.2f", usedMB))MB [\(file):\(line)]")
        }
    }
    
    /// 开始一个性能追踪会话
    /// - Parameters:
    ///   - name: 会话名称
    /// - Returns: 性能追踪会话对象
    public static func startSession(_ name: String) -> MagicPerformanceSession {
        return MagicPerformanceSession(name: name)
    }
}

/// 性能追踪会话类
public class MagicPerformanceSession {
    private let name: String
    private let startTime: CFAbsoluteTime
    private var checkpoints: [(name: String, time: CFAbsoluteTime)] = []
    
    fileprivate init(name: String) {
        self.name = name
        self.startTime = CFAbsoluteTimeGetCurrent()
        MagicPerformance.logger.debug("🎬 开始性能追踪会话: [\(name)]")
    }
    
    /// 记录检查点
    /// - Parameter name: 检查点名称
    public func checkpoint(_ name: String) {
        let time = CFAbsoluteTimeGetCurrent()
        checkpoints.append((name, time))
        
        if let lastCheckpoint = checkpoints.dropLast().last {
            let diff = time - lastCheckpoint.time
            MagicPerformance.logger.debug("⏱️ [\(self.name)] 检查点[\(name)] 距上次: \(String(format: "%.4f", diff))s")
        } else {
            let diff = time - startTime
            MagicPerformance.logger.debug("⏱️ [\(self.name)] 检查点[\(name)] 距开始: \(String(format: "%.4f", diff))s")
        }
    }
    
    /// 结束会话并获取报告
    /// - Returns: 性能报告字符串
    @discardableResult
    public func end() -> String {
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime
        
        var report = "性能追踪报告 [\(name)]\n"
        report += "总耗时: \(String(format: "%.4f", totalTime))s\n"
        
        if !checkpoints.isEmpty {
            report += "检查点详情:\n"
            var lastTime = startTime
            
            for (index, checkpoint) in checkpoints.enumerated() {
                let diff = checkpoint.time - lastTime
                report += "[\(index + 1)] \(checkpoint.name): \(String(format: "%.4f", diff))s\n"
                lastTime = checkpoint.time
            }
        }
        
        MagicPerformance.logger.debug("🏁 \(report)")
        return report
    }
}

