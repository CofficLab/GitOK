import Foundation
import MagicKit
import SwiftUI
import Sparkle

/// 检查更新视图模型
/// 负责管理更新检查的状态
final class CheckForUpdatesViewModel: ObservableObject, SuperLog {
    /// 日志标识符
    nonisolated static let emoji = "⬆️"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// 是否可以检查更新
    @Published var canCheckForUpdates = false

    /// 是否启用后台自动检查更新
    @Published var automaticallyChecksForUpdates = false

    /// 当前更新源
    @Published var feedURL: URL?

    init(updater: SPUUpdater) {
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
        updater.publisher(for: \.automaticallyChecksForUpdates)
            .assign(to: &$automaticallyChecksForUpdates)
        updater.publisher(for: \.feedURL)
            .assign(to: &$feedURL)
    }
}

/// 更新器视图组件
/// 提供检查应用更新的按钮功能
struct UpdaterView: View, SuperLog {
    /// 日志标识符
    nonisolated static let emoji = "⬆️"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// 检查更新视图模型
    @ObservedObject private var checkForUpdatesViewModel: CheckForUpdatesViewModel

    /// Sparkle 更新器
    private let updater: SPUUpdater

    @State private var isChecking = false

    init(updater: SPUUpdater) {
        self.updater = updater
        self.checkForUpdatesViewModel = CheckForUpdatesViewModel(updater: updater)
    }

    var body: some View {
        Button(isChecking ? "正在检查更新..." : "检查更新") {
            isChecking = true
            updater.checkForUpdates()

            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                isChecking = false
            }
        }
        .disabled(!checkForUpdatesViewModel.canCheckForUpdates || isChecking)
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .setInitialTab("Icon")
        .hideSidebar()
        .hideProjectActions()
        .setInitialTab("Icon")
        .inRootView()
        .frame(width: 800)
        .frame(height: 800)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideProjectActions()
        .setInitialTab("Icon")
        .hideSidebar()
        .setInitialTab("Icon")
        .inRootView()
        .frame(width: 800)
        .frame(height: 1200)
}
