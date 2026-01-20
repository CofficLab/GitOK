import Foundation
import OSLog
import ObjectiveC.runtime

@objc protocol PluginRegistrant {
    static func register()
}

class PluginRegistry {
    static let shared = PluginRegistry()

    private struct FactoryItem {
        let id: String
        let order: Int
        let factory: () -> any SuperPlugin
    }

    private var factoryItems: [FactoryItem] = []

    func register(id: String, order: Int = 0, factory: @escaping () -> any SuperPlugin) {
        factoryItems.append(FactoryItem(id: id, order: order, factory: factory))
    }

    func registerSync(id: String, order: Int = 0, factory: @escaping () -> any SuperPlugin) {
        register(id: id, order: order, factory: factory)
    }

    func buildAll() -> [any SuperPlugin] {
        factoryItems
            .sorted { $0.order < $1.order }
            .map { $0.factory() }
    }

    var count: Int {
        factoryItems.count
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

        // 检查是否符合SuperPlugin协议
        if let protocolPtr = objc_getProtocol("SuperPlugin"),
           class_conformsToProtocol(cls, protocolPtr) {

            os_log("✅ Found SuperPlugin class: \(className)")

            // 检查插件是否启用
            var enabled = true // 默认启用
            if let enableMethod = class_getClassMethod(cls, Selector("enable")) {
                typealias EnableGetter = @convention(c) (AnyClass) -> Bool
                let getter = unsafeBitCast(method_getImplementation(enableMethod), to: EnableGetter.self)
                enabled = getter(cls)
                os_log("🔧 Enable status for \(className): \(enabled)")
            } else {
                os_log("⚠️ No enable method found for \(className), using default: true")
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

            // 检查shared实例是否存在
            if let sharedInstance = cls.value(forKey: "shared") {
                os_log("✅ Found shared instance for \(className)")
            } else {
                os_log("❌ No shared instance found for \(className)")
                continue
            }

            // 直接注册插件到PluginRegistry（同步）
            PluginRegistry.shared.register(id: idValue, order: orderValue) {
                // 使用 shared 实例
                cls.value(forKey: "shared") as! any SuperPlugin
            }

            pluginCount += 1
        }
    }

    os_log("📊 Registered \(pluginCount) plugins total")
}
