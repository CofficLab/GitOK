import Foundation
import SwiftData
import SwiftUI

struct BannerModel2: TaskItem {
    static var root: String = ".gitok/banners"
    
    var title = ""
    var subTitle = ""
    var features: [String] = []
    var imageURL: URL?
    var backgroundId: String = "1"
    var uuid: String
    var taskUUID: String
    var inScreen = false
    var device: String = Device.iMac.rawValue
    var projectPath: String

    init(
        title: String = "",
        subTitle: String = "",
        features: [String] = [],
        imageURL: URL? = nil,
        backgroundId: String = "1",
        task: TaskModel,
        projectPath: String
    ) {
        self.title = title
        self.subTitle = subTitle
        self.imageURL = imageURL
        self.features = features
        self.backgroundId = backgroundId
        self.uuid = UUID().uuidString
        self.taskUUID = task.uuid
        self.projectPath = projectPath
        
        self.saveOnDisk()
    }
    
    func getDevice() -> Device {
        Device(rawValue: self.device)!
    }
    
    func toDoc() -> Doc {
        Doc(uuid: self.uuid, title: self.title, image: "photo.artframe")
    }
    
    func saveOnDisk() {
        let dir = "\(self.projectPath)/\(BannerModel.root)"
        let fullPath = "\(dir)/\(self.title).json"
//        Shell.makeDir(dir)
//        Shell.makeFile(fullPath, content: toJSONString() ?? "")
        
        self.saveToFile(atPath: fullPath)
    }
    
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
}

extension BannerModel2: Identifiable {
    var id: String {
        uuid
    }
}

extension BannerModel2: Codable {

}

#Preview {
    AppPreview()
}
