import Foundation
import OSLog
import ObjectiveC.runtime

@objc protocol PluginRegistrant {
    static func register()
}

class PluginRegistry {
    static let shared = PluginRegistry()

    private struct PluginItem {
        let id: String
        let order: Int
        let className: String
    }

    private var pluginItems: [PluginItem] = []

    func register(id: String, order: Int = 0, className: String) {
        pluginItems.append(PluginItem(id: id, order: order, className: className))
    }

    func getRegisteredPlugins() -> [(id: String, order: Int, className: String)] {
        pluginItems
            .sorted { $0.order < $1.order }
            .map { (id: $0.id, order: $0.order, className: $0.className) }
    }

    func buildAll() -> [any SuperPlugin] {
        // 由于实例创建移到了PluginProvider，这里返回空数组
        []
    }

    var count: Int {
        pluginItems.count
    }
}

func autoRegisterPlugins() {
    var count: UInt32 = 0
    guard let classList = objc_copyClassList(&count) else {
        os_log("❌ Failed to get class list")
        return
    }
    defer { free(UnsafeMutableRawPointer(classList)) }

    os_log("🔍 Found \(count) classes to check")

    let classes = UnsafeBufferPointer(start: classList, count: Int(count))
    var pluginCount = 0

    for i in 0 ..< classes.count {
        let cls: AnyClass = classes[i]
        let className = NSStringFromClass(cls)

        // 检查是否是插件类（通过类名）
        guard className.hasSuffix("Plugin") else { continue }

        os_log("✅ Found plugin class: \(className)")

        // 检查插件是否启用
        var enabled = true // 默认启用
        let enableSelector = Selector("enable")
        os_log("🔍 Looking for enable method in \(className)")

        if let enableMethod = class_getClassMethod(cls, enableSelector) {
            os_log("✅ Found enable method for \(className)")
            typealias EnableGetter = @convention(c) (AnyClass) -> Bool
            let getter = unsafeBitCast(method_getImplementation(enableMethod), to: EnableGetter.self)
            enabled = getter(cls)
            os_log("🔧 Enable status for \(className): \(enabled)")
        } else {
            os_log("⚠️ No enable method found for \(className), using default: true")
            // 注意：Swift静态属性不通过KVC暴露，所以这里使用默认值
            // 如果需要更精确的控制，可以考虑使用不同的机制
        }

        guard enabled else {
            os_log("⏭️ Skipping disabled plugin: \(className)")
            continue
        }

        // 记录插件注册日志
        os_log("🚀 Register plugin: \(className)")

        // 通过反射访问静态属性
        let idValue = cls.value(forKey: "id") as? String ?? className
        let orderValue = cls.value(forKey: "order") as? Int ?? 0

        os_log("📋 Plugin \(className) - id: \(idValue), order: \(orderValue)")

        // 注册插件信息到PluginRegistry
        PluginRegistry.shared.register(id: idValue, order: orderValue, className: className)

        pluginCount += 1
    }

    os_log("📊 Registered \(pluginCount) plugins total")
}
