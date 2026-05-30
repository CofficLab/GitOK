import SwiftUI

import GitOKPluginKit
import MagicAlert

/**
    Banner标签栏视图
    水平展示所有项目中的Banner项，点击切换当前选中Banner。
    直接与BannerRepo交互获取Banner列表数据，与BannerProvider保持同步。
**/
struct BannerTabs: View {
    @Environment(\.gitOKProjectURL) private var projectURL
    @EnvironmentObject var b: BannerProvider

    /// Banner数据源
    @State private var banners: [BannerFile] = []

    /// Banner仓库实例
    private let repo = BannerRepo.shared

    var body: some View {
        HStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(banners) { banner in
                        BannerTab(banner: banner)
                    }
                }
                .padding(.horizontal, 12)
            }

            // 添加新Banner按钮
            BannerBtnAdd()
                .frame(height: 28)
                .frame(width: 28)
                .padding(.trailing, 12)
        }
        .frame(height: 36)
        .onAppear {
            refreshBanners()
        }
        .onChange(of: projectURL) {
            refreshBanners()
        }
        .onBannerAdded { _ in
            refreshBanners()
        }
        .onBannerDidDelete { deletedId in
            refreshBanners()
            // 如果删除的是当前选中的banner，选择第一个可用的banner
            if deletedId == b.banner.id {
                if let firstBanner = banners.first {
                    b.setBanner(firstBanner)
                }
            }
        }
    }

    /// 刷新Banner列表
    private func refreshBanners() {
        if let projectURL {
            banners = repo.getBanners(from: projectURL)

            // 如果当前banner不在列表中，选择第一个可用的banner
            if !banners.contains(where: { $0.id == b.banner.id }) {
                if let firstBanner = banners.first {
                    b.setBanner(firstBanner)
                }
            }
        } else {
            banners = []
        }
    }
}
