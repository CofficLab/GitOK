import Foundation
import MagicKit
import OSLog
import StoreKit
import SwiftData
import SwiftUI

class PluginProvider: ObservableObject, SuperLog, SuperThread {
    let emoji = "🧩"
    @Published private(set) var plugins: [SuperPlugin] = []

    /// 检查插件是否被启用
    /// - Parameter plugin: 要检查的插件
    /// - Returns: 如果插件被启用则返回true
    /// - Note: 如果插件不可配置(isConfigurable = false)，则总是返回true
    private func isPluginEnabled(_ plugin: any SuperPlugin) -> Bool {
        // 如果插件不可由用户控制，则必须启用
        if !type(of: plugin).isConfigurable {
            return true
        }

        // 否则根据用户设置决定
        return PluginSettingsStore.shared.isPluginEnabled(plugin.instanceLabel)
    }

    /// 获取所有标记为标签页的插件
    /// - Returns: 可作为标签页显示的插件数组
    var tabPlugins: [SuperPlugin] {
        plugins.filter { $0.isTab }
    }

    /// 检查是否所有插件的列表视图都为空
    /// - Parameter
    ///      - tab: 当前选中的标签页
    ///     - project: 当前选中的项目
    /// - Returns: 如果所有插件的addListView都返回nil则返回true，否则返回false
    func allListViewsEmpty(tab: String, project: Project?) -> Bool {
        var allEmpty = true
        for plugin in plugins {
            if isPluginEnabled(plugin), let listView = plugin.addListView(tab: tab, project: project) {
                allEmpty = false
                break
            }
        }
        return allEmpty
    }

    /// 获取启用的工具栏前导视图
    /// - Returns: 启用的插件及其对应的工具栏前导视图数组
    func getEnabledToolbarLeadingViews() -> [(plugin: SuperPlugin, view: AnyView)] {
        plugins.compactMap { plugin in
            if isPluginEnabled(plugin), let view = plugin.addToolBarLeadingView() {
                return (plugin, view)
            }
            return nil
        }
    }

    /// 获取启用的工具栏后置视图
    /// - Returns: 启用的插件及其对应的工具栏后置视图数组
    func getEnabledToolbarTrailingViews() -> [(plugin: SuperPlugin, view: AnyView)] {
        plugins.compactMap { plugin in
            if isPluginEnabled(plugin), let view = plugin.addToolBarTrailingView() {
                return (plugin, view)
            }
            return nil
        }
    }

    /// 获取启用的插件列表视图
    /// - Parameters:
    ///   - tab: 当前选中的标签页
    ///   - project: 当前选中的项目
    /// - Returns: 启用的插件及其对应的列表视图数组
    func getEnabledPluginListViews(tab: String, project: Project?) -> [(plugin: SuperPlugin, view: AnyView)] {
        plugins.compactMap { plugin in
            if isPluginEnabled(plugin), let view = plugin.addListView(tab: tab, project: project) {
                return (plugin, view)
            }
            return nil
        }
    }

    /// 获取启用的标签页详情视图
    /// - Parameter tab: 标签页标识符
    /// - Returns: 如果找到启用的标签页插件，则返回其详情视图，否则返回nil
    func getEnabledTabDetailView(tab: String) -> AnyView? {
        if let tabPlugin = tabPlugins.first(where: { $0.instanceLabel == tab }),
           isPluginEnabled(tabPlugin) {
            return tabPlugin.addDetailView()
        }
        return nil
    }

    init(plugins: [SuperPlugin]) {
        let verbose = false
        if verbose {
            os_log("\(Self.onInit) PluginProvider")
        }

        self.plugins = plugins

        var labelCounts: [String: Int] = [:]
        for plugin in plugins {
            labelCounts[plugin.instanceLabel, default: 0] += 1
        }

        let duplicateLabels = labelCounts.filter { $0.value > 1 }.map { $0.key }
        if !duplicateLabels.isEmpty {
            assertionFailure("Duplicate labels: \(duplicateLabels)")
        }
    }

    /// 使用自动发现插件的初始化方法
    init(autoDiscover: Bool = true) {
        let verbose = false
        if verbose {
            os_log("\(Self.onInit) PluginProvider with auto discovery")
        }

        if autoDiscover {
            Task { [weak self] in
                guard let self else { return }
                await MainActor.run {
                    autoRegisterPlugins()
                }
                let discoveredPlugins = await PluginRegistry.shared.buildAll()
                await MainActor.run {
                    self.plugins = discoveredPlugins

                    // 检查重复标签
                    var labelCounts: [String: Int] = [:]
                    for plugin in discoveredPlugins {
                        labelCounts[plugin.instanceLabel, default: 0] += 1
                    }

                    let duplicateLabels = labelCounts.filter { $0.value > 1 }.map { $0.key }
                    if !duplicateLabels.isEmpty {
                        assertionFailure("Duplicate labels: \(duplicateLabels)")
                    }
                }
            }
        } else {
            self.plugins = []
        }
    }
}

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
        .hideProjectActions()
        .hideTabPicker()
        .inRootView()
        .frame(width: 800)
        .frame(height: 1000)
}
