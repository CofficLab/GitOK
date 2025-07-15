import Foundation
import MagicCore
import OSLog
import SwiftData
import SwiftUI

struct BannerModel: SuperJsonModel, SuperLog, SuperEvent {
    static var root: String = ".gitok/banners"
    static var label = "💿 BannerModel::"
    static var empty = BannerModel(path: "")

    var title = "BannerModel-Title"
    var subTitle = "BannerModel-SubTitle"
    var features: [String] = []
    var imageId: String?
    var backgroundId: String = "1"
    var inScreen = false
    var device: String = Device.iMac.rawValue
    var opacity: Double = 1.0
    var path: String
    var label: String = BannerModel.label
    var project: Project
    var titleColor: Color?
    var subTitleColor: Color?

    init(
        title: String = "",
        subTitle: String = "",
        features: [String] = [],
        imageId: String = "", // 更新参数名
        backgroundId: String = "1",
        path: String
    ) {
        self.title = title
        self.subTitle = subTitle
        self.features = features
        self.imageId = imageId // 更新赋值
        self.backgroundId = backgroundId
        self.path = path
        self.project = Project(Self.getProjectURL(path))
    }

    func getDevice() -> Device {
        Device(rawValue: device)!
    }

    func getImage() -> Image {
        var image = Image("Snapshot-1")

        if getDevice() == .iPad {
            image = Image("Snapshot-iPad")
        }

        if let smartImage = getSmartImage() {
            image = smartImage.getImage(self.project.url)
        }

        return image
    }

    func getSmartImage() -> SmartImage? {
        guard let imageId = self.imageId else {
            return nil
        }

        return SmartImage.fromImageId(imageId)
    }

    mutating func changeImage(_ url: URL) throws {
        if let imageId = self.imageId {
            try SmartImage.removeImage(imageId, projectURL: self.project.url)
        }

        let newImageId = try SmartImage.saveImage(url, projectURL: self.project.url)
        self.imageId = newImageId
        try self.saveToDisk()
    }
}

// MARK: Set

extension BannerModel {
    func setProject(_ project: Project) -> BannerModel {
        var newBanner = self
        newBanner.project = project
        return newBanner
    }
}

// MARK: Store

extension BannerModel {
    static func fromFile(_ jsonFile: URL) throws -> BannerModel {
        let jsonData = try Data(contentsOf: jsonFile)

        do {
            var banner = try JSONDecoder().decode(BannerModel.self, from: jsonData)
            banner.path = jsonFile.path
            banner.project = Project(Self.getProjectURL(jsonFile.path))

            return banner
        } catch {
            os_log(.error, "Error decoding JSON: \(error)")

            throw error
        }
    }

    func saveImage(_ url: URL) throws -> String {
        let ext = url.pathExtension
        let rootURL = URL(fileURLWithPath: path).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent(Self.root).deletingLastPathComponent()
        let imagesFolder = rootURL.appendingPathComponent("images")
        let storeURL = imagesFolder.appendingPathComponent("\(Date.nowCompact).\(ext)")

        os_log("\(self.t)SaveImage")
        os_log("  ➡️ \(url.relativeString)")
        os_log("  ➡️ \(storeURL.relativeString)")

        do {
            // Ensure the images directory exists
            try FileManager.default.createDirectory(at: imagesFolder, withIntermediateDirectories: true, attributes: nil)

            // Copy the image to the new location
            try FileManager.default.copyItem(at: url, to: storeURL)
            return storeURL.relativePath.replacingOccurrences(of: self.project.path, with: "")
        } catch let e {
            os_log(.error, "\(Self.label)SaveImage -> \(e.localizedDescription)")
            os_log(.error, "  ⚠️ \(e)")

            throw e
        }
    }

    func saveToDisk() throws {
        try self.save()
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .bannerTitleChanged, object: self, userInfo: ["title": title, "id": id])
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .bannerChanged, object: self)
        }
    }
}

extension BannerModel: Identifiable {
    var id: String {
        self.path ?? ""
    }
}

// MARK: Codable

extension BannerModel: Codable {
    enum CodingKeys: String, CodingKey {
        case backgroundId
        case device
        case features
        case inScreen
        case imageId
        case subTitle
        case title
        case opacity
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        backgroundId = try container.decode(String.self, forKey: .backgroundId)
        device = try container.decode(String.self, forKey: .device)
        features = try container.decode([String].self, forKey: .features)
        inScreen = try container.decode(Bool.self, forKey: .inScreen)
        imageId = try container.decodeIfPresent(String.self, forKey: .imageId)
        subTitle = try container.decode(String.self, forKey: .subTitle)
        title = try container.decode(String.self, forKey: .title)
        opacity = try container.decode(Double.self, forKey: .opacity)
        path = ""

        // 由于 project 不参与解码，我们需要设置一个默认值或者在其他地方设置
        project = .null
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(backgroundId, forKey: .backgroundId)
        try container.encode(device, forKey: .device)
        try container.encode(features, forKey: .features)
        try container.encode(inScreen, forKey: .inScreen)
        try container.encode(imageId, forKey: .imageId)
        try container.encode(subTitle, forKey: .subTitle)
        try container.encode(title, forKey: .title)
        try container.encode(opacity, forKey: .opacity)
        // 注意：这里没有编码 project
    }
}

// MARK: 查

extension BannerModel {
    static func find(_ path: String) throws -> BannerModel? {
        try BannerModel.fromFile(URL(fileURLWithPath: path))
    }

    static func all(_ project: Project) throws -> [BannerModel] {
        let verbose = false

        var models: [BannerModel] = []

        // 目录路径
        let directoryPath = "\(project.path)/\(Self.root)"

        if verbose {
            os_log("\(BannerModel.label)GetBanners from ➡️ \(directoryPath)")
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
                models.append(try BannerModel.fromFile(fileURL))
            }
        } catch {
            print("Error while enumerating files: \(error.localizedDescription)")
        }

        return models
    }

    static func getProjectURL(_ bannerPath: String, reason: String = "") -> URL {
        let verbose = false
        var projectURL = URL.null

        let pathURL = URL(fileURLWithPath: bannerPath)
        let pathString = pathURL.path
        if let range = pathString.range(of: "/\(Self.root)/") {
            let projectPath = String(pathString[..<range.lowerBound])

            projectURL = URL(fileURLWithPath: projectPath)
        }

        if verbose {
            os_log("banner url -> \(bannerPath)")
            os_log("banner project url -> \(projectURL.relativeString)")
        }

        return projectURL
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

// MARK: Error

enum BannerModelError: Error {
    case bannerPathIsEmpty
    case JSONError
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideTabPicker()
//            .hideProjectActions()
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
