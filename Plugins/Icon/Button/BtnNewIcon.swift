import MagicCore
import MagicAlert
import SwiftUI

struct BtnNewIcon: View {
    @EnvironmentObject var g: DataProvider
    @EnvironmentObject var m: MagicMessageProvider

    var body: some View {
        if let project = g.project {
            TabBtn(title: "新建 Icon", imageName: "plus.circle") {
                do {
                    let model = try IconData.new(project)
                    m.info("新建 Icon(\(model.title)) 成功")
                } catch {
                    m.error(error.localizedDescription)
                }
            }
        }
    }
} 

#Preview("App - Small Screen") {
    RootView {
        ContentLayout().setInitialTab(IconPlugin.label)
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout().setInitialTab(IconPlugin.label)
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
