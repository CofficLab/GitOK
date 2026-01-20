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
        if class_conformsToProtocol(cls, PluginRegistrant.self),
           let registrantType = cls as? PluginRegistrant.Type {

            // 检查插件是否启用，只有启用的插件才注册
            // 通过 Objective-C runtime 检查 enable 属性的值
            if let enableValue = cls.value(forKey: "enable") as? Bool {
                guard enableValue else { continue }
            }

            // 记录插件注册日志
            let className = NSStringFromClass(cls)
            os_log(.info, "🚀 Register plugin: \(className)")

            registrantType.register()
        }
    }
}
