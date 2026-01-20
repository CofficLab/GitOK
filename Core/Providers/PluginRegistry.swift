import Foundation
import OSLog
import ObjectiveC.runtime

/// 插件注册表
/// 负责自动发现和管理所有插件实例
class PluginRegistry {
    /// 单例实例
    static let shared = PluginRegistry()

    /// 已注册的插件实例列表
    private var registeredPlugins: [any SuperPlugin] = []

    private init() {}

    /// 注册一个插件实例
    /// - Parameter plugin: 要注册的插件实例
    func register(_ plugin: any SuperPlugin) {
        registeredPlugins.append(plugin)
    }

    /// 获取所有已注册的插件实例，按 order 排序
    /// - Returns: 排序后的插件实例数组
    func getAllPlugins() -> [any SuperPlugin] {
        registeredPlugins.sorted { type(of: $0).order < type(of: $1).order }
    }

    /// 已注册插件数量
    var count: Int {
        registeredPlugins.count
    }

    /// 清空所有注册的插件
    func clear() {
        registeredPlugins.removeAll()
    }
}

/// 自动发现并注册所有插件
/// 通过扫描 Objective-C runtime 中所有以 "Plugin" 结尾的类
func registerAllPlugins() {
    let registry = PluginRegistry.shared

    // 清空已有注册（防止重复注册）
    registry.clear()

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
        registry.register(plugin)
        os_log("🚀 Registered plugin: \(className) (order: \(type(of: plugin).order))")
    }

    os_log("📊 Registered \(registry.count) plugins total")
}
