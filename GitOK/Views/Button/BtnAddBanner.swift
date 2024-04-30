import SwiftUI
import OSLog

struct BtnAddBanner: View {
    @EnvironmentObject var app: AppManager
    
    var task: TaskModel
    var label = "🖥️ BtnAddBanner::"
    
    var body: some View {
        SmartButton(
            title: "添加Banner",
            systemImage: "photo.badge.plus.fill",
            onTap: {
                os_log("\(self.label)Create Banner")
                if let project = app.project {
                    task.addBanner(project)
                }
            })
    }
}

#Preview {
    AppPreview()
}
