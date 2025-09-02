import MagicCore
import SwiftUI
import OSLog

/**
    背景选择器
    以网格形式展示所有可用的背景渐变，用户可以点击选择并切换背景。
    直接从BannerProvider获取和修改背景数据，实现自包含的组件设计。
    
    ## 功能特性
    - 网格布局显示背景选项
    - 当前选中状态的视觉反馈
    - 响应式布局适应不同屏幕尺寸
    - 流畅的交互体验
    - 自动保存背景更改
**/
struct Backgrounds: View {
    @EnvironmentObject var b: BannerProvider
    @EnvironmentObject var m: MagicMessageProvider
    
    /// Banner仓库实例
    private let bannerRepo = BannerRepo.shared
    
    /// 网格列数，根据容器宽度自适应
    private let columns = [
        GridItem(.adaptive(minimum: 60, maximum: 80), spacing: 8)
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(0 ..< MagicBackgroundGroup.all.count, id: \.self) { index in
                    let gradient = MagicBackgroundGroup.all[index]
                    makeItem(gradient)
                        .frame(width: 60, height: 60)
                }
            }
            .padding(12)
        }
        .frame(minHeight: 120, maxHeight: 300)
    }

    /**
        创建单个背景选项
        
        ## 参数
        - `gradient`: 渐变背景类型
        
        ## 返回值
        返回可点击的背景选项视图
    */
    func makeItem(_ gradient: MagicBackgroundGroup.GradientName) -> some View {
        let isSelected = b.banner.backgroundId == gradient.rawValue
        
        return Button(action: {
            print("🎨 选择背景: \(gradient.rawValue), 当前背景: \(b.banner.backgroundId)")
            updateBackground(gradient.rawValue)
        }) {
            ZStack {
                MagicBackgroundGroup(for: gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)

                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.accentColor, lineWidth: 3)
                        .shadow(color: .accentColor.opacity(0.3), radius: 4, x: 0, y: 0)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    /**
        更新Banner背景
        修改背景ID并自动保存到磁盘
        
        ## 参数
        - `backgroundId`: 新的背景ID
    */
    private func updateBackground(_ backgroundId: String) {
        guard b.banner != .empty else { 
            m.error("Banner为空，无法更新背景")
            return
        }
        
        print("🔄 更新背景从 \(b.banner.backgroundId) 到 \(backgroundId)")
        
        var updatedBanner = b.banner
        updatedBanner.backgroundId = backgroundId
        
        // 更新Provider中的状态
        b.setBanner(updatedBanner)
        
        print("✅ Provider状态已更新，新背景: \(b.banner.backgroundId)")
        
        // 保存到磁盘
        do {
            try bannerRepo.saveBanner(updatedBanner)
            print("💾 背景已保存到磁盘")
        } catch {
            print("❌ 保存失败: \(error.localizedDescription)")
            m.error("保存背景失败：\(error.localizedDescription)")
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
