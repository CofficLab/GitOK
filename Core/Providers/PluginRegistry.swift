import Foundation
import OSLog
import ObjectiveC.runtime

@objc protocol PluginRegistrant {
    static func register()
}

actor PluginRegistry {
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

    func buildAll() -> [any SuperPlugin] {
        factoryItems
            .sorted { $0.order < $1.order }
            .map { $0.factory() }
    }
}

@MainActor
func autoRegisterPlugins() {
    var count: UInt32 = 0
    guard let classList = objc_copyClassList(&count) else { return }
    defer { free(UnsafeMutableRawPointer(classList)) }

    let classes = UnsafeBufferPointer(start: classList, count: Int(count))
    for i in 0 ..< classes.count {
        let cls: AnyClass = classes[i]
        if let protocolPtr = objc_getProtocol("SuperPlugin"),
           class_conformsToProtocol(cls, protocolPtr) {

            // 检查插件是否启用，只有启用的插件才注册
            // 通过 Objective-C runtime 访问 enable 静态属性
            var enabled = true // 默认启用
            if let enableMethod = class_getClassMethod(cls, Selector("enable")) {
                typealias EnableGetter = @convention(c) (AnyClass) -> Bool
                let getter = unsafeBitCast(method_getImplementation(enableMethod), to: EnableGetter.self)
                enabled = getter(cls)
            }
            guard enabled else { continue }

            // 记录插件注册日志
            let className = NSStringFromClass(cls)
            os_log("🚀 Register plugin: \(className)")

            // 直接注册插件到PluginRegistry
            Task {
                // 通过反射访问静态属性
                let idValue = cls.value(forKey: "id") as? String ?? className
                let orderValue = cls.value(forKey: "order") as? Int ?? 0

                await PluginRegistry.shared.register(id: idValue, order: orderValue) {
                    // 使用 shared 实例
                    cls.value(forKey: "shared") as! any SuperPlugin
                }
            }
        }
    }
}
