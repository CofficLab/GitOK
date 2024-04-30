import Foundation
import SwiftData
import SwiftUI

@Model class IconModel: Identifiable, TaskItem {
    static var root: String = ".gitok/banners"
    static var label = "💿 IconModel::"
    
    var title: String = "1"
    var iconId: Int = 1
    var backgroundId: String = "2"
    var imageURL: URL? = nil
    var uuid: String = ""
    var taskUUID: String = ""
    
    init(title: String = "1", iconId: Int = 1, backgroundId: String = "3", imageURL: URL? = nil, task: TaskModel) {
        self.title = title
        self.iconId = iconId
        self.backgroundId = backgroundId
        self.imageURL = imageURL
        self.uuid = UUID().uuidString
        self.taskUUID = task.uuid
    }
    
    func toDoc() -> Doc {
        Doc(uuid: self.uuid, title: self.title, image: "globe.europe.africa")
    }
}

#Preview {
    AppPreview()
}
