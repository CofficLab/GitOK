import Foundation
import KernelCore
import ProviderStorage

// MARK: - Contract

/// 自动推送提供能力协议
///
/// 维护「每个项目是否在提交后自动推送到上游」的开关（对齐旧版 AutoPush 能力）。
/// 消费方（状态栏图标 / 提交表单）通过 `isEnabled(for:)` 查询。
@MainActor
public protocol AutoPushProviding: AnyObject {
    /// 该项目是否启用了提交后自动推送。
    func isEnabled(for projectURL: URL) -> Bool

    /// 设置/关闭该项目的自动推送。
    func setEnabled(_ enabled: Bool, for projectURL: URL)
}

// MARK: - Default Implementation

/// `AutoPushProviding` 默认实现：开关持久化到
/// `StorageProviding.pluginDataDirectory(for: "AutoPush")` 下的 JSON 文件。
@MainActor
public final class DefaultAutoPushProvider: AutoPushProviding {
    private let storage: any StorageProviding
    private var settings: [String: Bool]
    private let fileURL: URL

    public init(storage: any StorageProviding) {
        self.storage = storage
        let directory = storage.pluginDataDirectory(for: "AutoPush")
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        self.fileURL = directory.appendingPathComponent("settings.json")
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([String: Bool].self, from: data) {
            self.settings = decoded
        } else {
            self.settings = [:]
        }
    }

    public func isEnabled(for projectURL: URL) -> Bool {
        settings[key(for: projectURL)] == true
    }

    public func setEnabled(_ enabled: Bool, for projectURL: URL) {
        settings[key(for: projectURL)] = enabled
        save()
    }

    private func key(for projectURL: URL) -> String {
        projectURL.standardizedFileURL.path
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
