import GitOKCoreKit
import GitOKUI
import MagicAlert
import GitOKSupportKit
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
            AppIconButton(systemImage: "plus", tint: .accentColor, size: .regular) {
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
                title: BannerPluginLocalization.string("New Banner")
            )

            // 设置为当前选中的Banner
            b.setBanner(newBanner)

            alert_info(BannerPluginLocalization.string("New Banner file added"))
        } catch {
            os_log(.error, "❌ 创建 Banner 失败: \(error.localizedDescription)")
            let msg = String.localizedStringWithFormat(
                BannerPluginLocalization.string("Failed to create Banner: %@"),
                error.localizedDescription
            )
            alert_error(msg)
        }
    }
}
