import Foundation
import SwiftData
import SwiftUI

@Model
class BannerModel: TaskItem {
    var title = ""
    var subTitle = ""
    var features: [String] = []
    var imageURL: URL?
    var backgroundId: String = "1"
    var uuid: String
    var taskUUID: String
    var inScreen = false
    var device: String = Device.iMac.rawValue

    init(
        title: String = "",
        subTitle: String = "",
        features: [String] = [],
        imageURL: URL? = nil,
        backgroundId: String = "1",
        task: TaskModel
    ) {
        self.title = title
        self.subTitle = subTitle
        self.imageURL = imageURL
        self.features = features
        self.backgroundId = backgroundId
        self.uuid = UUID().uuidString
        self.taskUUID = task.uuid
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
