import Foundation
import OSLog
import SwiftData
import SwiftUI

struct BannerModel {
    static var root: String = ".gitok/banners"
    static var label = "💿 BannerModel::"

    var title = ""
    var subTitle = ""
    var features: [String] = []
    var imageURL: URL?
    var backgroundId: String = "1"
    var inScreen = false
    var device: String = Device.iMac.rawValue
    var projectPath: String?

    init(
        title: String = "",
        subTitle: String = "",
        features: [String] = [],
        imageURL: URL? = nil,
        backgroundId: String = "1",
        projectPath: String
    ) {
        self.title = title
        self.subTitle = subTitle
        self.imageURL = imageURL
        self.features = features
        self.backgroundId = backgroundId
        self.projectPath = projectPath

        self.save()
    }

    func getDevice() -> Device {
        Device(rawValue: self.device)!
    }

    func save() {
        guard let p = projectPath else {
            return
        }
        
        let fullPath = "\(p)/\(BannerModel.root)/\(title).json"
        self.saveToFile(atPath: fullPath)
    }
}

// MARK: Store

extension BannerModel {
    // 将对象转换为 JSON 字符串
    func toJSONString() -> String? {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
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

    static func fromJSONFile(_ jsonFile: URL) -> BannerModel? {
        if let jsonData = try? Data(contentsOf: URL(fileURLWithPath: jsonFile.path)) {
            do {
                return try JSONDecoder().decode(BannerModel.self, from: jsonData)
            } catch {
                print("Error decoding JSON: \(error)")
            }
        }

        return nil
    }
}

extension BannerModel: Identifiable {
    var id: String {
        projectPath ?? "" + title
    }
}

// MARK: Hashable

extension BannerModel: Hashable {
    
}

// MARK: Equatable

extension BannerModel: Equatable {
    
}

// MARK: Codeable

extension BannerModel: Codable {
    enum CodingKeys: String, CodingKey {
        case title
        case subTitle
        case features
        case imageURL
        case backgroundId
        case inScreen
        case device
    }
}

// MARK: 查

extension BannerModel {
    static func all(_ projectPath: String) -> [BannerModel] {
        var models: [BannerModel] = []

        // 目录路径
        let directoryPath = "\(projectPath)/\(Self.root)"

        os_log("\(BannerModel.label)GetBanners from ->\(directoryPath)")

        // 创建 FileManager 实例
        let fileManager = FileManager.default

        // 存储文件路径的数组
        var fileURLs: [URL] = []

        do {
            // 获取指定目录下的文件列表
            let files = try fileManager.contentsOfDirectory(atPath: directoryPath)

            // 遍历文件列表，获取完整路径并存入数组
            for file in files {
                let fileURL = URL(fileURLWithPath: directoryPath).appendingPathComponent(file)
                fileURLs.append(fileURL)

                if let model = BannerModel.fromJSONFile(fileURL) {
                    models.append(model)
                }
            }
        } catch {
            print("Error while enumerating files: \(error.localizedDescription)")
        }

        return models
    }
}

// MARK: 新建

extension BannerModel {
    static func new(_ project: Project) -> BannerModel {
        BannerModel(title: "\(Int.random(in: 1 ... 100))", subTitle: "sub3", features: [
            "Feature 1",
            "Feature 2",
            "Feature 3",
            "Feature 4",
        ], projectPath: project.path)
    }
}

// MARK: 更新

extension BannerModel {
    mutating func updateBackgroundId(_ id: String) {
        self.backgroundId = id
        self.save()
    }
}

#Preview {
    AppPreview()
}
