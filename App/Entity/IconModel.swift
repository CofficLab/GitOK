import Foundation
import OSLog
import SwiftData
import SwiftUI
import MagicKit

struct IconModel: JsonModel, SuperEvent, SuperLog {
    static var root: String = ".gitok/icons"
    static var label = "💿 IconModel::"
    static var empty = IconModel(path: "")

    var title: String = "1"
    var iconId: Int = 1
    var backgroundId: String = "2"
    var imageURL: URL?
    var path: String?
    var opacity: Double = 1
    var scale: Double?

    var image: Image {
        if let url = self.imageURL {
            return Image(nsImage: NSImage(data: try! Data(contentsOf: url))!)
        }

        return IconPng.getImage(self.iconId)
    }

    var background: some View {
        BackgroundGroup(for: self.backgroundId).opacity(self.opacity)
    }

    var label: String { IconModel.label }

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
            os_log("\(IconModel.label)GetIcons from ->\(directoryPath)")
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
    }
}

// MARK: Hashable

extension IconModel: Hashable {
}

// MARK: Equatable

extension IconModel: Equatable {
}

// MARK: Identifiable

extension IconModel: Identifiable {
    var id: String {
        path ?? "" + title
    }
}

// MARK: 新建

extension IconModel {
    static func new(_ project: Project) -> Self {
        IconModel(title: "\(Int.random(in: 1 ... 100))", path: project.path + "/" + IconModel.root + "/" + UUID().uuidString + ".json")
    }
}

// MARK: 更新

extension IconModel {
    mutating func updateBackgroundId(_ id: String) throws {
        self.backgroundId = id
        try self.save()
    }

    mutating func updateIconId(_ id: Int) throws {
        self.iconId = id
        try self.save()
    }

    mutating func updateImageURL(_ url: URL) throws {
        self.imageURL = url
        try self.save()
    }
}

// MARK: 保存

extension IconModel {
    // 将对象转换为 JSON 字符串
    func toJSONString() -> String? {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
            let jsonData = try encoder.encode(self)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
        } catch {
            os_log(.error, "Error encoding BannerModel to JSON: \(error)")
        }
        return nil
    }

    // 保存 JSON 字符串到文件
    func saveToFile(atPath path: String) {
        if let jsonString = self.toJSONString() {
            // 创建 FileManager 实例
            let fileManager = FileManager.default

            // 确保父文件夹存在，如果不存在则创建
            let directoryURL = URL(fileURLWithPath: path).deletingLastPathComponent()
            do {
                try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                os_log(.error, "Error creating directory: \(error)")
            }

            do {
                try jsonString.write(toFile: path, atomically: true, encoding: .utf8)
                os_log(.info, "JSON saved to file: \(path)")
            } catch {
                os_log(.error, "Error saving JSON to file: \(error)")
            }
        }
    }

    func saveToDisk() throws {
        try self.save()
        self.emitIconDidSave()
    }

    static func fromJSONFile(_ jsonFile: URL) throws -> Self {
        let jsonData = try Data(contentsOf: jsonFile)
        do {
            var model = try JSONDecoder().decode(IconModel.self, from: jsonData)
            model.path = jsonFile.path
            return model
        } catch {
            os_log(.error, "Error decoding JSON: \(error)")
            os_log(.error, "  ➡️ JSONFile: \(jsonFile)")

            throw error
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
