import Foundation
import MagicKit
import ObjectiveC.runtime
import OSLog
import StoreKit
import SwiftData
import SwiftUI

class PluginProvider: ObservableObject, SuperLog, SuperThread {
    nonisolated static let emoji = "🧩"
    static let verbose = true

    @Published private(set) var plugins: [SuperPlugin] = []

    // MARK: - Plugin Registration

    /// 已注册的插件实例列表
    private var registeredPlugins: [any SuperPlugin] = []

    /// 注册一个插件实例
    /// - Parameter plugin: 要注册的插件实例
    private func register(_ plugin: any SuperPlugin) {
        registeredPlugins.append(plugin)
    }

    /// 获取所有已注册的插件实例，按 order 排序
    /// - Returns: 排序后的插件实例数组
    private func getAllPlugins() -> [any SuperPlugin] {
        registeredPlugins.sorted { type(of: $0).order < type(of: $1).order }
    }

    /// 清空所有注册的插件
    private func clearRegisteredPlugins() {
        registeredPlugins.removeAll()
    }

    /// 已注册插件数量
    private var registeredCount: Int {
        registeredPlugins.count
    }

    /// 自动发现并注册所有插件
    /// 通过扫描 Objective-C runtime 中所有以 "Plugin" 结尾的类
    private func autoDiscoverAndRegisterPlugins() {
        // 清空已有注册（防止重复注册）
        clearRegisteredPlugins()

        var count: UInt32 = 0
        guard let classList = objc_copyClassList(&count) else {
            os_log(.error, "\(self.t)❌ Failed to get class list")
            return
        }
        defer { free(UnsafeMutableRawPointer(classList)) }

        if Self.verbose { os_log("\(self.t)🔍 Scanning classes for plugins...") }

        let classes = UnsafeBufferPointer(start: classList, count: Int(count))

        // 临时存储发现的插件，用于排序
        var discoveredPlugins: [(plugin: any SuperPlugin, className: String, order: Int)] = []

        for i in 0 ..< classes.count {
            let cls: AnyClass = classes[i]
            let className = NSStringFromClass(cls)

            // 只检查 GitOK 命名空间下以 "Plugin" 结尾的类
            guard className.hasPrefix("GitOK."), className.hasSuffix("Plugin") else { continue }

            // 尝试获取 shared 单例实例
            let sharedSelector = NSSelectorFromString("shared")
            guard let sharedMethod = class_getClassMethod(cls, sharedSelector) else {
                if Self.verbose { os_log("\(Self.t)⚠️ No @objc shared found for \(className), skipping") }
                continue
            }

            // 调用 shared 方法获取实例
            typealias SharedGetter = @convention(c) (AnyClass, Selector) -> AnyObject?
            let getter = unsafeBitCast(method_getImplementation(sharedMethod), to: SharedGetter.self)

            guard let instance = getter(cls, sharedSelector) else {
                if Self.verbose { os_log("\(self.t)⚠️ Failed to get shared instance for \(className)") }
                continue
            }

            // 检查实例是否符合 SuperPlugin 协议
            guard let plugin = instance as? any SuperPlugin else {
                if Self.verbose { os_log("\(self.t)⚠️ Instance of \(className) does not conform to SuperPlugin") }
                continue
            }

            // 获取插件类型
            let pluginType = type(of: plugin)
            let pluginOrder = pluginType.order

            // 检查插件是否应该注册
            if !pluginType.shouldRegister {
                if Self.verbose { os_log("\(self.t)⏭️ Skipping plugin (shouldRegister=false): \(className)") }
                continue
            }

            // 检查用户是否禁用了此插件（仅当允许用户切换时）
            if pluginType.allowUserToggle {
                let pluginId = plugin.instanceLabel
                if PluginSettingsStore.shared.hasUserConfigured(pluginId) {
                    let enabled = PluginSettingsStore.shared.isPluginEnabled(pluginId, defaultEnabled: true)
                    if !enabled {
                        if Self.verbose { os_log("\(self.t)⏭️ Skipping plugin (user disabled): \(className)") }
                        continue
                    }
                }
            }

            // 添加到临时数组，稍后按 order 排序
            discoveredPlugins.append((plugin, className, pluginOrder))
        }

        // 按 order 排序后注册
        discoveredPlugins.sort { $0.order < $1.order }

        for (plugin, className, order) in discoveredPlugins {
            register(plugin)
            if Self.verbose { os_log("\(self.t)🚀 #\(order) Registered: \(className)") }
        }

        if Self.verbose {
            os_log("\(self.t)📊 Registered \(self.registeredCount) plugins total")
        }
    }

    // MARK: - Plugin Query Methods

    /// 获取所有标记为标签页的插件
    /// - Returns: 可作为标签页显示的插件数组
    var tabPlugins: [SuperPlugin] {
        plugins.filter { $0.addTabItem() != nil }
    }

    /// 获取所有可用的标签页名称
    /// - Returns: 标签页名称数组
    var tabNames: [String] {
        plugins.compactMap { $0.addTabItem() }
    }

    /// 检查是否所有插件的列表视图都为空
    /// - Parameter
    ///      - tab: 当前选中的标签页
    ///     - project: 当前选中的项目
    /// - Returns: 如果所有插件的addListView都返回nil则返回true，否则返回false
    func allListViewsEmpty(tab: String, project: Project?) -> Bool {
        for plugin in plugins {
            if let listView = plugin.addListView(tab: tab, project: project) {
                return false
            }
        }
        return true
    }

    /// 获取工具栏前导视图
    /// - Returns: 插件及其对应的工具栏前导视图数组
    func getEnabledToolbarLeadingViews() -> [(plugin: SuperPlugin, view: AnyView)] {
        plugins.compactMap { plugin in
            guard let view = plugin.addToolBarLeadingView() else { return nil }
            return (plugin, view)
        }
    }

    /// 获取工具栏后置视图
    /// - Returns: 插件及其对应的工具栏后置视图数组
    func getEnabledToolbarTrailingViews() -> [(plugin: SuperPlugin, view: AnyView)] {
        plugins.compactMap { plugin in
            guard let view = plugin.addToolBarTrailingView() else { return nil }
            return (plugin, view)
        }
    }

    /// 获取插件列表视图
    /// - Parameters:
    ///   - tab: 当前选中的标签页
    ///   - project: 当前选中的项目
    /// - Returns: 插件及其对应的列表视图数组
    func getEnabledPluginListViews(tab: String, project: Project?) -> [(plugin: SuperPlugin, view: AnyView)] {
        plugins.compactMap { plugin in
            guard let view = plugin.addListView(tab: tab, project: project) else { return nil }
            return (plugin, view)
        }
    }

    /// 获取标签页详情视图
    /// - Parameter tab: 标签页标识符
    /// - Returns: 如果找到标签页插件，则返回其详情视图，否则返回nil
    func getEnabledTabDetailView(tab: String) -> AnyView? {
        for plugin in plugins {
            if let view = plugin.addDetailView(for: tab) {
                return view
            }
        }
        return nil
    }

    // MARK: - Initialization

    init() {
        // 自动发现并注册所有插件
        autoDiscoverAndRegisterPlugins()

        // 从内部注册表获取所有已注册的插件实例
        self.plugins = getAllPlugins()

        // 检查重复标签
        var labelCounts: [String: Int] = [:]
        for plugin in plugins {
            labelCounts[plugin.instanceLabel, default: 0] += 1
        }

        let duplicateLabels = labelCounts.filter { $0.value > 1 }.map { $0.key }
        if !duplicateLabels.isEmpty {
            os_log("❌ Duplicate plugin labels: \(duplicateLabels)")
            assertionFailure("Duplicate labels: \(duplicateLabels)")
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
