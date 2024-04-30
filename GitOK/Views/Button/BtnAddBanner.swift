import SwiftUI

struct BtnAddBanner: View {
    var task: TaskModel
    
    var body: some View {
        SmartButton(
            title: "添加Banner",
            systemImage: "photo.badge.plus.fill",
            onTap: {
                task.addBanner()
            })
    }
}

#Preview {
    AppPreview()
}
