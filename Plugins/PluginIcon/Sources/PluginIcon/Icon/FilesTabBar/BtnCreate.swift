import OSLog
import GitOKCoreKit
import SwiftUI

struct BtnCreate: View {
    let projectURL: URL?

    init(projectURL: URL? = nil) {
        self.projectURL = projectURL
    }

    var body: some View {
        if let projectURL {
            Image.add.inButtonWithAction {
                do {
                    let model = try IconData.new(projectURL: projectURL)
                    alert_info("新建 Icon(\(model.title)) 成功")
                } catch {
                    os_log(.error, "❌ 创建 Icon 失败: \(error.localizedDescription)")
                    alert_error(error.localizedDescription)
                }
            }
        }
    }
}
