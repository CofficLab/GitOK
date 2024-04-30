import Foundation
import SwiftData
import SwiftUI

@Model class TaskModel {
    var createdAt: Date
    var title: String = "新任务"
    var subTitle: String = ""
    var uuid: String = ""

    init() {
        createdAt = .now
        uuid = UUID().uuidString
    }

    static func makeSample() -> TaskModel {
        let task = TaskModel()
        task.title = "新任务\(Int.random(in: 1 ... 100))"
        task.subTitle = "let us make it easy"
        _ = [
            BannerModel(title: "\(Int.random(in: 1 ... 100))", subTitle: "sub1", task: task),
            BannerModel(title: "\(Int.random(in: 1 ... 100))", subTitle: "sub2", task: task),
            BannerModel(title: "\(Int.random(in: 1 ... 100))", subTitle: "sub3", features: [
                "Feature 1",
                "Feature 2",
                "Feature 3",
                "Feature 4",
            ], task: task),
        ]

        return task
    }

    func addBanner(_ project: Project) {
        let banner = BannerModel(title: "\(Int.random(in: 1 ... 100))", subTitle: "sub3", features: [
            "Feature 1",
            "Feature 2",
            "Feature 3",
            "Feature 4",
        ], task: self)

        if let context = modelContext {
            context.insert(banner)
        }
        
        BannerShell.new(banner.title, path: project.path)
    }

    func addIcon() {
        let icon = IconModel(title: "\(Int.random(in: 1 ... 100))", task: self)
        
        if let context = modelContext {
            context.insert(icon)
        }
    }

    // MARK: 删除

    func delete(_ context: ModelContext) {
        context.delete(self)
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
