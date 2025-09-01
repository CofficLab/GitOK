import MagicCore
import SwiftUI
import OSLog

/**
    透明度编辑修改器
    以类似Backgrounds.swift的方式提供透明度编辑功能。
    直接从BannerProvider获取和修改数据，实现自包含的组件设计。
    
    ## 功能特性
    - 透明度滑块调节
    - 实时预览效果
    - 预设透明度选项
    - 自动保存更改
**/
struct OpacityEditor: View {
    @EnvironmentObject var b: BannerProvider
    @EnvironmentObject var m: MagicMessageProvider
    
    /// Banner仓库实例
    private let bannerRepo = BannerRepo.shared
    
    /// 预设透明度选项
    private let presetOpacities: [Double] = [0.25, 0.5, 0.75, 1.0]
    
    var body: some View {
        VStack(spacing: 16) {
            // 透明度滑块
            GroupBox("透明度调节") {
                VStack(spacing: 12) {
                    HStack {
                        Slider(
                            value: Binding(
                                get: { b.banner.opacity },
                                set: { newValue in
                                    updateOpacity(newValue)
                                }
                            ),
                            in: 0.1...1.0,
                            step: 0.05
                        )
                        
                        Text("\(Int(b.banner.opacity * 100))%")
                            .frame(width: 40)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    /**
        更新Banner透明度
        修改透明度并自动保存到磁盘
        
        ## 参数
        - `newOpacity`: 新的透明度值
    */
    private func updateOpacity(_ newOpacity: Double) {
        guard b.banner != .empty else { 
            m.error("Banner为空，无法更新透明度")
            return
        }
        
        // 确保透明度在有效范围内
        let clampedOpacity = max(0.1, min(1.0, newOpacity))
        
        var updatedBanner = b.banner
        updatedBanner.opacity = clampedOpacity
        
        // 更新Provider中的状态
        b.setBanner(updatedBanner)
        
        // 保存到磁盘
        do {
            try bannerRepo.saveBanner(updatedBanner)
        } catch {
            m.error("保存透明度失败：\(error.localizedDescription)")
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(BannerPlugin.label)
            .hideSidebar()
            .hideTabPicker()
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
