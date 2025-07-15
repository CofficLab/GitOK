import Foundation
import OSLog
import SwiftData
import SwiftUI
import MagicCore

struct IconModel: SuperJsonModel, SuperEvent, SuperLog {
    static var root: String = ".gitok/icons"
    static var emoji = "💿"
    static var empty = IconModel(path: "")

    var title: String = "1"
    var iconId: Int = 1
    var backgroundId: String = "2"
    var imageURL: URL?
    var path: String
    var opacity: Double = 1
    var scale: Double? = 1

    var image: Image {
        if let url = self.imageURL {
            return Image(nsImage: NSImage(data: try! Data(contentsOf: url))!)
        }

        return IconPng.getImage(self.iconId)
    }

    var background: some View {
        MagicBackgroundGroup(for: self.backgroundId).opacity(self.opacity)
    }

    init(title: String = "1", iconId: Int = 1, backgroundId: String = "3", imageURL: URL? = nil, path: String) {
        self.title = title
        self.iconId = iconId
        self.backgroundId = backgroundId
        self.imageURL = imageURL
        self.path = path
    }
}

// MARK: 查

extension IconModel {
    static func all(_ projectPath: String) throws -> [IconModel] {
        let verbose = false
        var models: [IconModel] = []

        // 目录路径
        let directoryPath = "\(projectPath)/\(Self.root)"

        if verbose {
            os_log("\(t)GetIcons from ->\(directoryPath)")
        }

        // 创建 FileManager 实例
        let fileManager = FileManager.default

        var isDir: ObjCBool = true
        if !fileManager.fileExists(atPath: directoryPath, isDirectory: &isDir) {
            return []
        }

        do {
            for file in try fileManager.contentsOfDirectory(atPath: directoryPath) {
                let fileURL = URL(fileURLWithPath: directoryPath).appendingPathComponent(file)

                models.append(try IconModel.fromJSONFile(fileURL))
            }

            return models
        } catch {
            os_log(.error, "Error while enumerating files: \(error.localizedDescription)")

            throw error
        }
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
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decode(String.self, forKey: .title)
        self.iconId = try container.decode(Int.self, forKey: .iconId)
        self.backgroundId = try container.decode(String.self, forKey: .backgroundId)
        self.imageURL = try container.decodeIfPresent(URL.self, forKey: .imageURL)
        self.opacity = try container.decodeIfPresent(Double.self, forKey: .opacity) ?? 1.0
        self.scale = try container.decodeIfPresent(Double.self, forKey: .scale)
        self.path = ""
    }
}

// MARK: 新建

extension IconModel {
    @discardableResult
    static func new(_ project: Project) throws -> Self {
        let title = "新图标-\(Int.random(in: 1 ... 100))"
        let path = project.path + "/" + IconModel.root + "/" + UUID().uuidString + ".json"
        let iconId = Int.random(in: 1 ... 100)
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

    mutating func updateBackgroundId(_ id: String) throws {
        self.backgroundId = id
        try self.saveToDisk()
    }

    mutating func updateIconId(_ id: Int) throws {
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

// MARK: 通知

extension Notification.Name {
    static let iconDidChange = Notification.Name("iconDidChange")
    static let iconDidSave = Notification.Name("iconDidSave")
    static let iconDidFail = Notification.Name("iconDidFail")
    static let iconDidGet = Notification.Name("iconDidGet")
    static let iconTitleDidChange = Notification.Name("iconTitleDidChange")
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
