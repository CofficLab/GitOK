import Foundation
import OSLog
import SwiftUI
import MagicCore

struct IconModel: SuperJsonModel, SuperEvent, SuperLog {
    static var emoji = "💿"
    static var empty = IconModel(path: "")

    var title: String = "1"
    var iconId: String = "1"
    var backgroundId: String = "2"
    var imageURL: URL?
    var path: String
    var opacity: Double = 1
    var scale: Double? = 1
    var cornerRadius: Double = 0

    var image: Image {
        if let url = self.imageURL {
            return Image(nsImage: NSImage(data: try! Data(contentsOf: url))!)
        }

        // 通过IconRepo获取IconAsset，然后获取Image
        if let iconAsset = AppIconRepo.shared.getIconAsset(byId: self.iconId) {
            return iconAsset.getImage()
        }
        
        return Image(systemName: "plus")
    }

    var background: some View {
        MagicBackgroundGroup(for: self.backgroundId).opacity(self.opacity)
    }

    init(title: String = "1", iconId: String = "1", backgroundId: String = "3", imageURL: URL? = nil, path: String) {
        self.title = title
        self.iconId = iconId
        self.backgroundId = backgroundId
        self.imageURL = imageURL
        self.path = path
        self.cornerRadius = 0
    }
}

// MARK: Codable

extension IconModel: Codable {
    enum CodingKeys: String, CodingKey {
        case title
        case iconId
        case backgroundId
        case imageURL
        case opacity
        case scale
        case cornerRadius
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
        self.path = ""
    }
}

// MARK: 新建

extension IconModel {
    @discardableResult
    static func new(_ project: Project) throws -> Self {
        let title = "新图标-\(Int.random(in: 1 ... 100))"
        let path = project.path + "/" + ProjectIconRepo.iconStoragePath + "/" + UUID().uuidString + ".json"
        let iconId = String(Int.random(in: 1 ... 100))
        let model = IconModel(title: title, iconId: iconId, path: path)
        try model.saveToDisk()
        return model
    }
}

// MARK: 更新

extension IconModel {
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

// MARK: 保存

extension IconModel {
    func saveToDisk() throws {
        try self.save()
        self.emit(.iconDidSave)
    }

    static func fromJSONFile(_ jsonFile: URL) throws -> Self {
        let jsonData = try Data(contentsOf: jsonFile)
        do {
            var model = try JSONDecoder().decode(IconModel.self, from: jsonData)
            model.path = jsonFile.path
            return model
        } catch {
            os_log(.error, "\(self.t)Error decoding JSON: \(error)")
            os_log(.error, "  ➡️ JSONFile: \(jsonFile)")

            throw error
        }
    }
}

// MARK: 删除

extension IconModel {
    func deleteFromDisk() throws {
        self.delete()
        self.emit(.iconDidDelete, object: nil, userInfo: ["path": self.path])
    }
}

// MARK: 通知

extension Notification.Name {
    static let iconDidChange = Notification.Name("iconDidChange")
    static let iconDidSave = Notification.Name("iconDidSave")
    static let iconDidFail = Notification.Name("iconDidFail")
    static let iconDidGet = Notification.Name("iconDidGet")
    static let iconTitleDidChange = Notification.Name("iconTitleDidChange")
    static let iconDidDelete = Notification.Name("iconDidDelete")
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout().setInitialTab("Icon")
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout().setInitialTab("Icon")
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
