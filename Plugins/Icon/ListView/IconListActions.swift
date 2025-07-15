import SwiftUI
import MagicCore

struct IconListActions: View {
    @EnvironmentObject var g: DataProvider
    @EnvironmentObject var m: MagicMessageProvider

    var body: some View {
        if let project = g.project {
            HStack(spacing: 0) {
                TabBtn(title: "新建 Icon", imageName: "plus.circle", onTap: {
                    do {
                        let model = try IconModel.new(project)
                        m.info("新建 Icon(\(model.title)) 成功")
                    } catch {
                        m.error(error.localizedDescription)
                    }
                })
            }
            .frame(height: 25)
            .labelStyle(.iconOnly)
        }
    }
} 

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideProjectActions()
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
