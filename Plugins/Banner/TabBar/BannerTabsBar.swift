import SwiftUI
import MagicCore

/**
    Banner标签栏视图
    水平展示所有项目中的Banner项，点击切换当前选中Banner。
    直接与BannerRepo交互获取Banner列表数据。
**/
struct BannerTabsBar: View {
    @EnvironmentObject var b: BannerProvider
    @EnvironmentObject var g: DataProvider
    @EnvironmentObject var m: MagicMessageProvider
    
    /// Banner数据源
    @State private var banners: [BannerData] = []

    /// 当前选中的Banner
    @Binding var selection: BannerData?
    
    /// Banner仓库实例
    private let bannerRepo = BannerRepo.shared

    var body: some View {
        HStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(banners) { banner in
                        BannerTab(banner: banner, selection: $selection)
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
        .onChange(of: g.project) {
            refreshBanners()
        }
        .onBannerAdded { _ in
            refreshBanners()
        }   
        .onBannerDidSave { _ in
            let selectedId = selection?.id
            refreshBanners()
            // 保持选中状态
            if let selectedId = selectedId {
                selection = banners.first(where: { $0.id == selectedId })
            }
        }
        .onBannerDidDelete { deletedId in
            refreshBanners()
            // 如果删除的是当前选中的banner，清除选中状态
            if deletedId == selection?.id {
                selection = banners.first
            }
        }
    }

    /// 刷新Banner列表
    private func refreshBanners() {
        if let project = g.project {
            banners = bannerRepo.getBanners(from: project)
            
            // 如果没有选中项或选中项不在列表中，选择第一个
            if selection == nil || !banners.contains(where: { $0.id == selection?.id }) {
                selection = banners.first
            }
        } else {
            banners = []
            selection = nil
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
            .hideProjectActions()
            .hideTabPicker()
    }
    .frame(width: 800)
    .frame(height: 1000)
}
