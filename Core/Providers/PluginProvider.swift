import Foundation
import MagicKit
import ObjectiveC.runtime
import OSLog
import StoreKit
import SwiftData
import SwiftUI

class PluginProvider: ObservableObject, SuperLog, SuperThread {
    let emoji = "🧩"
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
            os_log("❌ Failed to get class list")
            return
        }
        defer { free(UnsafeMutableRawPointer(classList)) }

        os_log("🔍 Scanning classes for plugins...")

        let classes = UnsafeBufferPointer(start: classList, count: Int(count))

        for i in 0 ..< classes.count {
            let cls: AnyClass = classes[i]
            let className = NSStringFromClass(cls)

            // 只检查 GitOK 命名空间下以 "Plugin" 结尾的类
            guard className.hasPrefix("GitOK."), className.hasSuffix("Plugin") else { continue }

            // 检查插件是否启用
            var enabled = true // 默认启用
            let enableSelector = NSSelectorFromString("enable")
            if let enableMethod = class_getClassMethod(cls, enableSelector) {
                typealias EnableGetter = @convention(c) (AnyClass, Selector) -> Bool
                let getter = unsafeBitCast(method_getImplementation(enableMethod), to: EnableGetter.self)
                enabled = getter(cls, enableSelector)
            } else {
                os_log("⚠️ No enable method found for \(className), using default: true")
            }

            guard enabled else {
                os_log("⏭️ Skipping disabled plugin: \(className)")
                continue
            }

            // 尝试获取 shared 单例实例
            let sharedSelector = NSSelectorFromString("shared")
            guard let sharedMethod = class_getClassMethod(cls, sharedSelector) else {
                os_log("⚠️ No @objc shared found for \(className), skipping")
                continue
            }

            // 调用 shared 方法获取实例
            typealias SharedGetter = @convention(c) (AnyClass, Selector) -> AnyObject?
            let getter = unsafeBitCast(method_getImplementation(sharedMethod), to: SharedGetter.self)

            guard let instance = getter(cls, sharedSelector) else {
                os_log("⚠️ Failed to get shared instance for \(className)")
                continue
            }

            // 检查实例是否符合 SuperPlugin 协议
            guard let plugin = instance as? any SuperPlugin else {
                os_log("⚠️ Instance of \(className) does not conform to SuperPlugin")
                continue
            }

            // 注册插件
            register(plugin)
            os_log("🚀 Registered plugin: \(className) (order: \(type(of: plugin).order))")
        }

        os_log("📊 Registered \(self.registeredCount) plugins total")
    }

    // MARK: - Plugin Query Methods

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
        plugins.filter { $0.addTabItem() != nil }
    }

    /// 获取所有可用的标签页名称
    /// - Returns: 标签页名称数组
    var tabNames: [String] {
        plugins.compactMap { plugin in
            if isPluginEnabled(plugin), let tabName = plugin.addTabItem() {
                return tabName
            }
            return nil
        }
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
        for plugin in plugins {
            if isPluginEnabled(plugin), let view = plugin.addDetailView(for: tab) {
                return view
            }
        }
        return nil
    }

    // MARK: - Initialization

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
        os_log("🏭 PluginProvider init with autoDiscover: \(autoDiscover)")

        if autoDiscover {
            os_log("🔄 Starting plugin auto-discovery and registration")
            // 自动发现并注册所有插件
            autoDiscoverAndRegisterPlugins()

            os_log("📦 Loading plugin instances")
            // 从内部注册表获取所有已注册的插件实例
            self.plugins = getAllPlugins()

            os_log("📊 PluginProvider initialized with \(self.plugins.count) plugins")

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
        } else {
            os_log("⏭️ Auto discovery disabled")
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
