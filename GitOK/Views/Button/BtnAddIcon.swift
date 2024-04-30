import SwiftUI

struct BtnAddIcon: View {
    var task: TaskModel

    var body: some View {
        SmartButton(
            title: "添加Icon",
            systemImage: "pencil.tip.crop.circle.badge.plus",
            onTap: {
                task.addIcon()
            })
    }
}

#Preview {
    BannerPreview()
}
