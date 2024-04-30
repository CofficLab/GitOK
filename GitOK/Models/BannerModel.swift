import Foundation
import SwiftData
import SwiftUI

@Model
final class BannerModel: TaskItem {
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
        
        let banner2 = BannerModel2(title: self.title, task: task, projectPath: projectPath)
        banner2.saveOnDisk()
    }
    
    func getDevice() -> Device {
        Device(rawValue: self.device)!
    }
    
    func toDoc() -> Doc {
        Doc(uuid: self.uuid, title: self.title, image: "photo.artframe")
    }
}

extension BannerModel: Identifiable {
    
}

#Preview {
    AppPreview()
}
