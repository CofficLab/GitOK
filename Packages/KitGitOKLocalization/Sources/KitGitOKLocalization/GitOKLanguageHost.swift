import Foundation
import SwiftUI

/// 界面语言变更的观察器。
///
/// 视图用它订阅 `GitOKLanguageOverride.didChangeNotification`，
/// 在语言切换后重建视图树，使所有 `pluginLocalization.string(_:)`
/// 的求值结果随之更新。
@MainActor
public final class GitOKLanguageObserver: ObservableObject {
    /// 语言变更时递增，供视图作为 `.id(...)` 的依赖。
    @Published public private(set) var revision: UInt64 = 0

    /// 订阅任务。用 async 序列而非 `addObserver`，
    /// 避免跨并发域传递 `NSObjectProtocol` 令牌。
    nonisolated(unsafe) private var subscription: Task<Void, Never>?

    public init() {
        subscription = Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(
                named: GitOKLanguageOverride.didChangeNotification
            ) {
                self?.revision &+= 1
            }
        }
    }

    deinit {
        subscription?.cancel()
    }
}

/// 绑定界面语言的视图容器。
///
/// 通过 `.id(revision)` 在语言切换后重建内容视图，
/// 确保所有依赖语言求值的文案立即刷新。
public struct GitOKLanguageHost<Content: View>: View {
    private let content: Content
    @StateObject private var observer = GitOKLanguageObserver()

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .id(observer.revision)
            .environment(\.locale, Locale(identifier: GitOKLocalization.effectiveLanguageCode))
    }
}
