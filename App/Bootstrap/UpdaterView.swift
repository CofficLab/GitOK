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

    init(updater: SPUUpdater) {
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
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

    init(updater: SPUUpdater) {
        self.updater = updater
        self.checkForUpdatesViewModel = CheckForUpdatesViewModel(updater: updater)
    }

    var body: some View {
        Button("检查更新", action: updater.checkForUpdates)
            .disabled(!checkForUpdatesViewModel.canCheckForUpdates)
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .setInitialTab(IconPlugin.label)
        .hideSidebar()
        .hideProjectActions()
        .setInitialTab(IconPlugin.label)
        .inRootView()
        .frame(width: 800)
        .frame(height: 800)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideProjectActions()
        .setInitialTab(IconPlugin.label)
        .hideSidebar()
        .setInitialTab(IconPlugin.label)
        .inRootView()
        .frame(width: 800)
        .frame(height: 1200)
}
