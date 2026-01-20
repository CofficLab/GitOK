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
        let protocolPtr = objc_getProtocol("SuperPlugin")
        os_log("🔍 Checking SuperPlugin protocol for \(className)")

        // 尝试多种检查方式
        var conformsToProtocol = false

        // 方法1: 使用objc_getProtocol
        if protocolPtr != nil && class_conformsToProtocol(cls, protocolPtr) {
            conformsToProtocol = true
            os_log("✅ Protocol check 1 succeeded for \(className)")
        }
        // 方法2: 直接检查类名是否包含"Plugin"
        else if className.hasSuffix("Plugin") {
            conformsToProtocol = true
            os_log("✅ Protocol check 2 succeeded for \(className) (by name)")
        }

        if conformsToProtocol {

            os_log("✅ Found SuperPlugin class: \(className)")

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
