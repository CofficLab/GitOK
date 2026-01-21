
import MagicAlert
import MagicUI
import SwiftUI

struct BtnCreate: View {
    @EnvironmentObject var g: DataProvider
    @EnvironmentObject var m: MagicMessageProvider

    var body: some View {
        if let project = g.project {
            MagicButton.simple(icon: .iconAdd, title: "新建") {
                do {
                    let model = try IconData.new(project)
                    m.info("新建 Icon(\(model.title)) 成功")
                } catch {
                    m.error(error.localizedDescription)
                }
            }
            .magicSize(.auto)
        }
    }
} 

#Preview("App - Small Screen") {
    RootView {
        ContentLayout().setInitialTab("Icon")
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .hideProjectActions()
            .setInitialTab("Icon")
            .hideSidebar()
    }
    .frame(width: 800)
    .frame(height: 1200)
}
