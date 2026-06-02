
import SwiftUI

/**
 * Banner下载按钮组件
 * 提供多种格式的Banner下载功能
 * 支持PNG、JPEG、SVG等格式
 */
struct BannerDownloadButtons: View {
    @EnvironmentObject var bannerProvider: BannerProvider

    var body: some View {
        VStack(spacing: 8) {
            BannerPNGDownloadButton(template: bannerProvider.selectedTemplate)
                .environmentObject(bannerProvider)

            BannerAppStoreDownloadButton(template: bannerProvider.selectedTemplate)
                .environmentObject(bannerProvider)

            BanneriPhoneAppStoreDownloadButton(template: bannerProvider.selectedTemplate)
                .environmentObject(bannerProvider)

            if bannerProvider.banner.path.isEmpty {
                Text("请先选择一个Banner", tableName: "Localizable")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
        }
    }
}
