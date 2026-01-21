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

    /// 是否注册所有插件（开发调试用，设为 false 可禁用所有插件）
    static var registerAllPlugins: Bool = true

    @Published private(set) var plugins: [SuperPlugin] = []

    // MARK: - Plugin Registration

    /// 已注册的插件实例列表
    private var registeredPlugins: [any SuperPlugin] = []

    /// 已使用的插件标签集合（用于检测重复）
    private var usedLabels: Set<String> = []

    /// 注册一个插件实例
    /// - Parameter plugin: 要注册的插件实例
    private func register(_ plugin: any SuperPlugin) {
        let label = plugin.instanceLabel

        // 检查标签是否已存在
        if usedLabels.contains(label) {
            let pluginType = String(describing: type(of: plugin))
            os_log(.error, "\(Self.t)❌ Duplicate plugin label '\(label)' in \(pluginType)")
            assertionFailure("Duplicate plugin label: \(label)")
            return
        }

        // 标记该标签已使用
        usedLabels.insert(label)
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
        usedLabels.removeAll()
    }

    /// 已注册插件数量
    private var registeredCount: Int {
        registeredPlugins.count
    }

    /// 自动发现并注册所有插件
    /// 通过扫描 Objective-C runtime 中所有以 "Plugin" 结尾的类
    private func autoDiscoverAndRegisterPlugins() {
        // 检查是否禁用所有插件注册
        if !Self.registerAllPlugins {
            if Self.verbose { os_log("\(self.t)⚠️ Plugin registration is disabled via registerAllPlugins=false") }
            return
        }

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

    /// 检查插件是否被用户启用
    /// - Parameter plugin: 要检查的插件
    /// - Returns: 如果插件被启用则返回true
    private func isPluginEnabled(_ plugin: any SuperPlugin) -> Bool {
        let pluginType = type(of: plugin)

        // 如果不允许用户切换，则始终启用
        if !pluginType.allowUserToggle {
            return true
        }

        // 检查用户配置
        let pluginId = plugin.instanceLabel
        if PluginSettingsStore.shared.hasUserConfigured(pluginId) {
            return PluginSettingsStore.shared.isPluginEnabled(pluginId, defaultEnabled: true)
        }

        // 用户未配置过，默认启用
        return true
    }

    /// 获取所有可用的标签页名称
    /// - Returns: 标签页名称数组
    var tabNames: [String] {
        plugins
            .filter { isPluginEnabled($0) }
            .compactMap { $0.addTabItem() }
    }

    /// 获取可配置的插件信息列表（用于设置界面）
    /// - Returns: 允许用户切换启用/禁用状态的插件信息数组
    var configurablePlugins: [PluginInfo] {
        plugins
            .filter { type(of: $0).allowUserToggle }
            .map { plugin in
                let pluginType = type(of: plugin)
                let pluginId = plugin.instanceLabel
                return PluginInfo(
                    id: pluginId,
                    name: pluginType.displayName,
                    description: pluginType.description,
                    icon: pluginType.iconName,
                    isDeveloperEnabled: { true }
                )
            }
    }

    /// 获取工具栏前导视图
    /// - Returns: 插件及其对应的工具栏前导视图数组
    func getEnabledToolbarLeadingViews() -> [(plugin: SuperPlugin, view: AnyView)] {
        plugins.compactMap { plugin in
            guard isPluginEnabled(plugin) else { return nil }
            guard let view = plugin.addToolBarLeadingView() else { return nil }
            return (plugin, view)
        }
    }

    /// 获取工具栏后置视图
    /// - Returns: 插件及其对应的工具栏后置视图数组
    func getEnabledToolbarTrailingViews() -> [(plugin: SuperPlugin, view: AnyView)] {
        plugins.compactMap { plugin in
            guard isPluginEnabled(plugin) else { return nil }
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
            guard isPluginEnabled(plugin) else { return nil }
            guard let view = plugin.addListView(tab: tab, project: project) else { return nil }
            return (plugin, view)
        }
    }

    /// 获取标签页详情视图
    /// - Parameter tab: 标签页标识符
    /// - Returns: 如果找到标签页插件，则返回其详情视图，否则返回nil
    func getEnabledTabDetailView(tab: String) -> AnyView? {
        for plugin in plugins {
            guard isPluginEnabled(plugin) else { continue }
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
