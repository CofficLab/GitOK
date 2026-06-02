import GitOKFoundationKit
import GitOKDesignKit
import Combine
import Foundation
import OSLog
import SwiftUI

/// 全局下载进度监控器
///
/// 集中管理所有文件的下载进度监听，避免每个视图创建独立的监听器。
/// 使用单例模式和引用计数，确保每个 URL 只有一个监听器，当没有视图订阅时自动清理。
///
/// ## 优化说明
/// - 不使用 NSMetadataQuery，使用轻量级的 resourceValues 查询
/// - 已下载的文件不创建监听器，直接返回进度 1.0
/// - 使用轮询机制，每秒检查一次文件状态
/// - 将非 UI 操作移到后台线程执行，避免阻塞主线程
public final class AvatarDownloadMonitor: SuperLog {
    public static let emoji = "📥"

    /// 单例实例
    public static let shared = AvatarDownloadMonitor()

    /// 监听器信息
    private struct MonitorInfo {
        let publisher: CurrentValueSubject<Double, Never>
        var refCount: Int
        /// 用于取消监听
        var cancellable: AnyCancellable?
    }

    /// 监听器字典 [URL: MonitorInfo] - 使用 actor 确保线程安全
    private actor MonitorStore {
        var monitors: [URL: MonitorInfo] = [:]
        var activeMonitorCount: Int = 0

        func get(_ url: URL) -> MonitorInfo? {
            monitors[url]
        }

        func set(_ info: MonitorInfo, for url: URL) {
            monitors[url] = info
            activeMonitorCount = monitors.count
        }

        func remove(_ url: URL) -> MonitorInfo? {
            let removed = monitors.removeValue(forKey: url)
            activeMonitorCount = monitors.count
            return removed
        }

        /// 更新引用计数的结果
        enum RefCountUpdateResult {
            /// 监听器不存在
            case notFound
            /// 监听器仍在使用中（引用计数 > 0）
            case inUse(info: MonitorInfo, count: Int)
            /// 监听器已被移除（引用计数归零）
            case removed(removedInfo: MonitorInfo, count: Int)
        }

        func updateRefCount(for url: URL, increment: Bool) -> RefCountUpdateResult {
            guard var info = monitors[url] else {
                return .notFound
            }

            if increment {
                info.refCount += 1
                monitors[url] = info
                activeMonitorCount = monitors.count
                return .inUse(info: info, count: monitors.count)
            } else {
                info.refCount -= 1

                if info.refCount <= 0 {
                    // 引用计数归零，移除监听器
                    monitors.removeValue(forKey: url)
                    activeMonitorCount = monitors.count
                    return .removed(removedInfo: info, count: monitors.count)
                } else {
                    // 仍有其他订阅者
                    monitors[url] = info
                    return .inUse(info: info, count: monitors.count)
                }
            }
        }

        func getActiveCount() -> Int {
            activeMonitorCount
        }

        /// 获取所有活跃的监听器 URL
        func getActiveMonitors() -> [(url: URL, refCount: Int)] {
            monitors.map { ($0.key, $0.value.refCount) }
                .sorted { $0.refCount > $1.refCount }
        }
    }

    /// 线程安全的存储
    private let store = MonitorStore()

    /// 主线程上的活跃监听器数量（用于 UI 观察）
    @MainActor
    public private(set) var activeMonitorCount: Int = 0

    /// 订阅指定 URL 的下载进度
    ///
    /// 如果该 URL 已有监听器，增加引用计数并返回现有发布者。
    /// 如果没有，创建新的监听器并开始监控。
    ///
    /// - Parameter url: 要监听的文件 URL
    /// - Returns: 进度发布者，发送 0-1 之间的值
    public func subscribe(url: URL, verbose: Bool) async -> AnyPublisher<Double, Never> {
        // 检查是否已存在监听器
        if let existing = await store.get(url) {
            // 已存在，增加引用计数
            let result = await store.updateRefCount(for: url, increment: true)

            // 更新主线程上的计数
            let newCount: Int
            switch result {
            case let .inUse(info, count):
                newCount = count
                // 关键修复：即使是现有的监听器，也强制检查一次最新状态
                // 避免因为 Query 延迟或漏掉通知导致状态滞后
                let currentSnapshot = url.getDownloadProgressSnapshot()
                if currentSnapshot != info.publisher.value {
                    // 如果状态不一致（例如已下载完成但 publisher 还在 0.9），强制更新
                     if verbose {
                        os_log("\(Self.t)🔄 修正状态 [Old: \(info.publisher.value) -> New: \(currentSnapshot)]: \(url.lastPathComponent)")
                     }
                    info.publisher.send(currentSnapshot)
                }
                
                if verbose {
                    os_log("\(Self.t)🔺 增加引用 [引用: \(info.refCount), 总数: \(count)]: \(url.lastPathComponent)")
                }
            case let .removed(_, count):
                newCount = count
            case .notFound:
                newCount = await store.getActiveCount()
            }

            await MainActor.run {
                self.activeMonitorCount = newCount
            }

            return existing.publisher.eraseToAnyPublisher()
        }

        // 先查询初始进度，避免发送错误的初始值
        let initialProgress = url.getDownloadProgressSnapshot()

        // 使用正确的初始值创建监听器
        let publisher = CurrentValueSubject<Double, Never>(initialProgress)

        // 使用 URL 扩展方法创建监听
        let cancellable = url.onDownloading(
            verbose: verbose,
            caller: self.className,
            updateInterval: 0.1 // 10Hz 更新频率，保证 UI 流畅
        ) { progress in
            publisher.send(progress)
            
            if progress >= 1.0 {
                // 下载完成，发送 1.0
                publisher.send(1.0)
            }
        }

        let info = MonitorInfo(
            publisher: publisher,
            refCount: 1,
            cancellable: cancellable
        )

        await store.set(info, for: url)

        // 更新主线程上的计数
        let newCount = await store.getActiveCount()
        await MainActor.run {
            self.activeMonitorCount = newCount
        }

        if verbose {
            os_log("\(Self.t)➕ 创建监听器 [总数: \(newCount)]: \(url.lastPathComponent)")
        }

        return publisher.eraseToAnyPublisher()
    }

    /// 取消订阅指定 URL 的下载进度
    ///
    /// 减少引用计数，当引用计数归零时清理该 URL 的监听器。
    ///
    /// - Parameter url: 要取消订阅的文件 URL
    public func unsubscribe(url: URL, verbose: Bool) async {
        let result = await store.updateRefCount(for: url, increment: false)

        // 更新主线程上的计数
        let newCount: Int
        switch result {
        case .notFound:
            newCount = await store.getActiveCount()
            // 监听器不存在，静默忽略（可能是重复取消订阅）

        case let .inUse(info, count):
            newCount = count
            // 还有其他订阅者，只是减少了引用计数
            if verbose {
                os_log("\(Self.t)🔻 减少引用 [引用: \(info.refCount), 总数: \(count)]: \(url.lastPathComponent)")
            }

        case let .removed(removedInfo, count):
            newCount = count
            // 引用计数归零，监听器已从 store 中移除，取消任务
            removedInfo.cancellable?.cancel()
            if verbose {
                os_log("\(Self.t)🗑️ 移除监听器 [剩余: \(count)]: \(url.lastPathComponent)")
            }
        }

        await MainActor.run {
            self.activeMonitorCount = newCount
        }
    }
}
