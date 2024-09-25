import Foundation
import OSLog
import SwiftData
import SwiftUI

struct BannerModel: JsonModel, SuperLog {
    static var root: String = ".gitok/banners"
    static var label = "💿 BannerModel::"
    static var empty = BannerModel(path: "")

    var title = "BannerModel-Title"
    var subTitle = "BannerModel-SubTitle"
    var features: [String] = []
    var imageURL: URL?
    var backgroundId: String = "1"
    var inScreen = false
    var device: String = Device.iMac.rawValue
    var opacity: Double = 1.0
    var path: String?
    var label: String = BannerModel.label

    init(
        title: String = "",
        subTitle: String = "",
        features: [String] = [],
        imageURL: URL? = nil,
        backgroundId: String = "1",
        path: String
    ) {
        self.title = title
        self.subTitle = subTitle
        self.imageURL = imageURL
        self.features = features
        self.backgroundId = backgroundId
        self.path = path

        if let path = self.path, path.isNotEmpty {
            save()
        }
    }

    func getDevice() -> Device {
        Device(rawValue: device)!
    }

    func getImage() -> Image {
        var image = Image("Snapshot-1")

        if getDevice() == .iPad {
            image = Image("Snapshot-iPad")
        }

        if let url = imageURL, let data = try? Data(contentsOf: url),
           let nsImage = NSImage(data: data) {
            image = Image(nsImage: nsImage)
        }

        return image
    }
}

// MARK: Store

extension BannerModel {
    static func fromFile(_ jsonFile: URL) -> BannerModel? {
        if let jsonData = try? Data(contentsOf: URL(fileURLWithPath: jsonFile.path)) {
            do {
                var banner = try JSONDecoder().decode(BannerModel.self, from: jsonData)
                banner.path = jsonFile.path

                return banner
            } catch {
                print("Error decoding JSON: \(error)")
            }
        }

        return nil
    }

    func saveImage(_ url: URL) throws -> URL {
        guard let path = self.path else {
            return url
        }
        
        let ext = url.pathExtension
        let rootURL = URL(fileURLWithPath: path).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent(Self.root).deletingLastPathComponent()
        let imagesFolder = rootURL.appendingPathComponent("images")
        let storeURL = imagesFolder.appendingPathComponent("\(TimeHelper.getTimeString()).\(ext)")
        
        os_log("\(self.t)SaveImage")
        os_log("  ➡️ \(url.relativeString)")
        os_log("  ➡️ \(storeURL.relativeString)")
        
        do {
            // Ensure the images directory exists
            try FileManager.default.createDirectory(at: imagesFolder, withIntermediateDirectories: true, attributes: nil)
            
            // Copy the image to the new location
            try FileManager.default.copyItem(at: url, to: storeURL)
            return storeURL
        } catch let e {
            os_log(.error, "\(Self.label)SaveImage -> \(e.localizedDescription)")
            os_log(.error, "  ⚠️ \(e)")

            throw e
        }
    }
}

// MARK: Codeable

extension BannerModel: Codable {
    enum CodingKeys: String, CodingKey {
        case backgroundId
        case device
        case features
        case inScreen
        case imageURL
        case subTitle
        case title
        case opacity
    }
}

// MARK: 查

extension BannerModel {
    static func find(_ path: String) -> BannerModel? {
        let fileURL = URL(fileURLWithPath: path)

        return BannerModel.fromFile(fileURL)
    }

    static func all(_ projectPath: String) -> [BannerModel] {
        var models: [BannerModel] = []

        // 目录路径
        let directoryPath = "\(projectPath)/\(Self.root)"

        os_log("\(BannerModel.label)GetBanners from ->\(directoryPath)")

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

                if let model = BannerModel.fromFile(fileURL) {
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
        let path = project.path + "/" + BannerModel.root + "/" + UUID().uuidString + ".json"
        
        return BannerModel(title: "\(Int.random(in: 1 ... 100))", subTitle: "sub3", features: [
            "Feature 1",
            "Feature 2",
            "Feature 3",
            "Feature 4",
        ], path: path)
    }
}

// MARK: 更新

extension BannerModel {
//    mutating func updateBackgroundId(_ id: String) {
//        self.backgroundId = id
//        self.save()
//    }
//
//    mutating func updateTitle(_ t: String) {
//        os_log("\(BannerModel.label)UpdateTitle->\(t)")
//        self.title = t
//        self.save()
//    }
//
//    mutating func updateSubTitle(_ t: String) {
//        self.subTitle = t
//        self.save()
//    }
//
//    mutating func updateImage(_ u: URL) {
//        self.imageURL = u
//        self.save()
//    }
//
//    mutating func updateFeatures(_ f: [String]) {
//        self.features = f
//        self.save()
//    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 600)
}
