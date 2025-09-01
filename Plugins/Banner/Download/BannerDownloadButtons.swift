import MagicCore
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
            BannerPNGDownloadButton()
                .environmentObject(bannerProvider)

            BannerAppStoreDownloadButton()
                .environmentObject(bannerProvider)

            BanneriPhoneAppStoreDownloadButton()
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
    RootView {
        ContentLayout()
            .setInitialTab(BannerPlugin.label)
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(BannerPlugin.label)
            .hideSidebar()
            .hideTabPicker()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 1000)
}
