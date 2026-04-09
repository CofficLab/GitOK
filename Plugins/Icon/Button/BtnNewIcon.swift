
import MagicAlert
import OSLog
import SwiftUI

struct BtnNewIcon: View {
    @EnvironmentObject var g: DataProvider
    @EnvironmentObject var vm: ProjectVM
    

    var body: some View {
        if let project = vm.project {
            TabBtn(title: "新建 Icon", imageName: "plus.circle") {
                do {
                    let model = try IconData.new(project)
                    alert_info("新建 Icon(\(model.title)) 成功")
                } catch {
                    os_log(.error, "❌ 创建 Icon 失败: \(error.localizedDescription)")
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
        ContentLayout().setInitialTab("Icon")
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
