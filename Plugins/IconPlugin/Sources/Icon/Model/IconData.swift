import Foundation
import GitOKCoreKit
import OSLog
import SwiftUI

/**
 * 图标数据模型
 * 纯数据存储结构，负责存储图标的配置信息
 * 不包含任何UI渲染逻辑，只负责数据的序列化和反序列化
 */
struct IconData: Codable, Identifiable, Equatable, Hashable {
    nonisolated static let emoji = "💿"
    nonisolated static let empty = IconData(path: "")

    /// 图标标题
    var title: String = "1"

    /// 图标资源ID（对应IconAsset的id）
    var iconId: String = "1"

    /// 背景样式ID
    var backgroundId: String = "2"

    /// 自定义图片URL（可选）
    var imageURL: URL?

    /// 配置文件路径
    var path: String

    /// 透明度（0.0 - 1.0）
    var opacity: Double = 1

    /// 缩放比例（可选）
    var scale: Double? = 1

    /// 圆角半径
    var cornerRadius: Double = 0

    /// 图标内边距（0.0 - 0.3）
    var padding: Double = 0.12

    var id: String { path }

    init(title: String = "1", iconId: String = "1", backgroundId: String = "3", imageURL: URL? = nil, path: String) {
        self.title = title
        self.iconId = iconId
        self.backgroundId = backgroundId
        self.imageURL = imageURL
        self.path = path
        self.cornerRadius = 0
    }
}

// MARK: - Codable

extension IconData {
    enum CodingKeys: String, CodingKey {
        case title
        case iconId
        case backgroundId
        case imageURL
        case opacity
        case scale
        case cornerRadius
        case padding
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decode(String.self, forKey: .title)
        // 兼容性处理：如果 iconId 是 Int，转换为 String
        if let intIconId = try? container.decode(Int.self, forKey: .iconId) {
            self.iconId = String(intIconId)
        } else {
            self.iconId = try container.decode(String.self, forKey: .iconId)
        }
        self.backgroundId = try container.decode(String.self, forKey: .backgroundId)
        self.imageURL = try container.decodeIfPresent(URL.self, forKey: .imageURL)
        self.opacity = try container.decodeIfPresent(Double.self, forKey: .opacity) ?? 1.0
        self.scale = try container.decodeIfPresent(Double.self, forKey: .scale)
        self.cornerRadius = try container.decodeIfPresent(Double.self, forKey: .cornerRadius) ?? 0.0
        self.padding = try container.decodeIfPresent(Double.self, forKey: .padding) ?? 0.12
        self.path = ""
    }
}

// MARK: - 新建

extension IconData {
    @discardableResult
    static func new(projectURL: URL) throws -> Self {
        let title = "新图标-\(Int.random(in: 1 ... 100))"
        let path = projectURL
            .appendingPathComponent(ProjectIconRepo.iconStoragePath)
            .appendingPathComponent("\(UUID().uuidString).json")
            .path
        let iconId = String(Int.random(in: 1 ... 100))
        let model = IconData(title: title, iconId: iconId, path: path)
        try model.saveToDisk()
        return model
    }
}

// MARK: - 更新

extension IconData {
    mutating func updateOpacity(_ o: Double) throws {
        self.opacity = o
        try self.saveToDisk()
    }

    mutating func updateScale(_ s: Double) throws {
        self.scale = s
        try self.saveToDisk()
    }

    mutating func updateCornerRadius(_ radius: Double) throws {
        self.cornerRadius = radius
        try self.saveToDisk()
    }

    mutating func updatePadding(_ p: Double) throws {
        self.padding = p
        try self.saveToDisk()
    }

    mutating func updateBackgroundId(_ id: String) throws {
        self.backgroundId = id
        try self.saveToDisk()
    }

    mutating func updateIconId(_ id: String) throws {
        self.iconId = id
        try self.saveToDisk()
    }

    mutating func updateImageURL(_ url: URL) throws {
        self.imageURL = url
        try self.saveToDisk()
    }
}

// MARK: - 保存

extension IconData {
    private func writeToDisk() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(self)
        let fileURL = URL(fileURLWithPath: path)
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: fileURL, options: .atomic)
    }

    func saveToDisk() throws {
        try writeToDisk()
        emit(.iconDidSave)
    }

    func saveToDiskAsync() async throws {
        try await Task.detached(priority: .utility) {
            try self.writeToDisk()
        }.value

        await MainActor.run {
            emit(.iconDidSave)
        }
    }

    static func fromJSONFile(_ jsonFile: URL) throws -> Self {
        let jsonData = try Data(contentsOf: jsonFile)
        do {
            var model = try JSONDecoder().decode(IconData.self, from: jsonData)
            model.path = jsonFile.path
            return model
        } catch {
            os_log(.error, "Error decoding JSON: \(error)")
            os_log(.error, "  ➡️ JSONFile: \(jsonFile)")

            throw error
        }
    }
}

// MARK: - 删除

extension IconData {
    func deleteFromDisk() throws {
        try FileManager.default.removeItem(atPath: path)
        self.emit(.iconDidDelete, object: nil, userInfo: ["path": self.path])
    }
}

// MARK: - 通知

extension IconData {
    func emit(_ name: Notification.Name, object: Any? = nil, userInfo: [AnyHashable: Any]? = nil) {
        NotificationCenter.default.post(name: name, object: object, userInfo: userInfo)
    }
}

extension Notification.Name {
    static let iconDidSave = Notification.Name("iconDidSave")
    static let iconDidDelete = Notification.Name("iconDidDelete")
}
