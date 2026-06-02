import GitOKCoreKit
import MagicAlert
import MagicKit
import OSLog
import SwiftUI

/**
     添加Banner按钮
     提供创建新Banner的功能，直接与BannerRepo交互进行创建操作。
 **/
struct BannerBtnAdd: View, SuperThread {
    let projectURL: URL?
    @EnvironmentObject var b: BannerProvider

    /// Banner仓库实例
    private let bannerRepo = BannerRepo.shared

    init(projectURL: URL? = nil) {
        self.projectURL = projectURL
    }

    var body: some View {
        if let projectURL {
            Image.add.inButtonWithAction {
                createBanner(in: projectURL)
            }
        }
    }

    /**
         创建新Banner
         直接调用repo层创建Banner，通知由repo层负责发送

         ## 参数
         - `projectURL`: 所属项目根目录
     */
    private func createBanner(in projectURL: URL) {
        do {
            let newBanner = try bannerRepo.createBanner(
                in: projectURL,
                title: String(localized: "New Banner", table: "Banner")
            )

            // 设置为当前选中的Banner
            b.setBanner(newBanner)

            alert_info(String(localized: "New Banner file added", table: "Banner"))
        } catch {
            os_log(.error, "❌ 创建 Banner 失败: \(error.localizedDescription)")
            let msg = String.localizedStringWithFormat(
                String(localized: "Failed to create Banner: %@", table: "Banner"),
                error.localizedDescription
            )
            alert_error(msg)
        }
    }
}
