import MagicAlert
import SwiftUI
import MagicKit

struct BtnCreate: View {
    @EnvironmentObject var g: DataProvider
    

    var body: some View {
        if let project = g.project {
            Image.add.inButtonWithAction {
                do {
                    let model = try IconData.new(project)
                    alert_info("新建 Icon(\(model.title)) 成功")
                } catch {
                    alert_error(error.localizedDescription)
                }
            }
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
