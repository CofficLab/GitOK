
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
                Text("请先选择一个Banner")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
        }
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .hideTabPicker()
        .inRootView()
        .frame(width: 800)
        .frame(height: 1000)
}

