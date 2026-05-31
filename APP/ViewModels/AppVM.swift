import AVKit
import MagicKit
import Combine
import Foundation
import MediaPlayer
import OSLog
import SwiftUI

/// 应用状态提供者，管理全局应用状态和用户界面控制
class AppVM: NSObject, ObservableObject, AVAudioPlayerDelegate, SuperLog {
    /// emoji 标识符
    nonisolated static let emoji = "🏠"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// 当前选中的标签页
    @Published var currentTab: String = "Git"

    /// 侧边栏是否可见
    @Published var sidebarVisibility: Bool

    /// 是否显示设置
    @Published var showSettings: Bool = false

    /// 默认打开的设置标签（nil 表示使用默认）
    @Published var defaultSettingTab: String? = nil

    /// 仓库管理器实例
    private let repoManager: RepoManager

    /// 初始化应用状态提供者
    /// - Parameter repoManager: 仓库管理器实例
    init(repoManager: RepoManager) {
        self.repoManager = repoManager
        self.sidebarVisibility = repoManager.stateRepo.sidebarVisibility

        super.init()
    }
}

// MARK: - Action

extension AppVM {
    /// 设置当前选中的标签页
    /// - Parameter t: 标签页名称
    func setTab(_ t: String) {
        if Self.verbose {
            os_log("\(self.t)Set Tab to \(t)")
        }

        self.currentTab = t
        repoManager.stateRepo.setCurrentTab(t)
    }

    /// 隐藏侧边栏
    func hideSidebar() {
        if Self.verbose {
            os_log("\(self.t)Hide Sidebar")
        }

        self.sidebarVisibility = false
        repoManager.stateRepo.setSidebarVisibility(false)
    }

    /// 显示侧边栏
    /// - Parameter reason: 显示侧边栏的原因
    func showSidebar(reason: String) {
        if Self.verbose {
            os_log("\(self.t)Show Sidebar(\(reason))")
        }
        self.sidebarVisibility = true
        repoManager.stateRepo.setSidebarVisibility(true)
    }

    /// 设置侧边栏可见性
    /// - Parameters:
    ///   - v: 是否可见
    ///   - reason: 设置的原因
    func setSidebarVisibility(_ v: Bool, reason: String) {
        v ? showSidebar(reason: reason) : hideSidebar()
    }

    /// 显示设置界面
    func openSettings() {
        showSettings = true
    }

    /// 打开插件管理设置
    func openPluginSettings() {
        defaultSettingTab = "plugins"
        showSettings = true
    }

    /// 打开仓库设置
    func openRepositorySettings() {
        defaultSettingTab = "repository"
        showSettings = true
    }

    /// 打开Commit风格设置
    func openCommitStyleSettings() {
        defaultSettingTab = "commitStyle"
        showSettings = true
    }
}

// MARK: - Preview

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}

