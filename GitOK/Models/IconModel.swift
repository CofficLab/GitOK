import Foundation
import SwiftData
import SwiftUI
import OSLog

struct IconModel: JsonModel {
    static var root: String = ".gitok/icons"
    static var label = "💿 IconModel::"
    static var empty = IconModel(path: "")
    
    var title: String = "1"
    var iconId: Int = 1
    var backgroundId: String = "2"
    var imageURL: URL? = nil
    var path: String?
    var opacity: Double = 1
    
    
    var image: Image {
        if let url = self.imageURL {
            return Image(nsImage: NSImage(data: try! Data(contentsOf: url))!)
        }

        return IconPng.getImage(self.iconId)
    }
    
    var background: some View {
        BackgroundGroup.all[self.backgroundId]
            .opacity(self.opacity)
    }
    
    var label: String { IconModel.label }
    
    init(title: String = "1", iconId: Int = 1, backgroundId: String = "3", imageURL: URL? = nil, path: String) {
        self.title = title
        self.iconId = iconId
        self.backgroundId = backgroundId
        self.imageURL = imageURL
        self.path = path
        
        self.save()
    }
}

// MARK: 查

extension IconModel {
    static func all(_ projectPath: String) -> [IconModel] {
        var models: [IconModel] = []

        // 目录路径
        let directoryPath = "\(projectPath)/\(Self.root)"

        os_log("\(IconModel.label)GetIcons from ->\(directoryPath)")

        // 创建 FileManager 实例
        let fileManager = FileManager.default
        
        var isDir: ObjCBool = true
        if !fileManager.fileExists(atPath: directoryPath, isDirectory: &isDir) {
            return []
        }

        // 存储文件路径的数组
        var fileURLs: [URL] = []

        do {
            // 获取指定目录下的文件列表
            let files = try fileManager.contentsOfDirectory(atPath: directoryPath)

            // 遍历文件列表，获取完整路径并存入数组
            for file in files {
                let fileURL = URL(fileURLWithPath: directoryPath).appendingPathComponent(file)
                fileURLs.append(fileURL)

                if var model = IconModel.fromJSONFile(fileURL) {
                    model.path = fileURL.path
                    models.append(model)
                }
            }
        } catch {
            print("Error while enumerating files: \(error.localizedDescription)")
        }

        return models
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
    mutating func updateBackgroundId(_ id: String) {
        self.backgroundId = id
        self.save()
    }
    
    mutating func updateIconId(_ id: Int) {
        self.iconId = id
        self.save()
    }
    
    mutating func updateImageURL(_ url: URL) {
        self.imageURL = url
        self.save()
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
            print("Error encoding BannerModel to JSON: \(error)")
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
                print("Error creating directory: \(error)")
            }

            do {
                try jsonString.write(toFile: path, atomically: true, encoding: .utf8)
                print("JSON saved to file: \(path)")
            } catch {
                print("Error saving JSON to file: \(error)")
            }
        }
    }
    
    static func fromJSONFile(_ jsonFile: URL) -> Self? {
        if let jsonData = try? Data(contentsOf: URL(fileURLWithPath: jsonFile.path)) {
            do {
                return try JSONDecoder().decode(IconModel.self, from: jsonData)
            } catch {
                print("Error decoding JSON: \(error)")
            }
        }

        return nil
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
