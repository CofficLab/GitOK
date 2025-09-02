import MagicCore
import OSLog
import SwiftUI

/**
     Banner详情布局视图
     主要的Banner编辑界面，包含顶部的Banner标签页和主要的编辑区域。
 **/
struct BannerDetailLayout: View {
    static var shared = BannerDetailLayout()

    @EnvironmentObject var g: DataProvider
    @EnvironmentObject var m: MagicMessageProvider
    @EnvironmentObject var b: BannerProvider

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    var body: some View {
        GeometryReader { geometry in
            HSplitView {
                VStack(spacing: 0) {
                    BannerTabs()
                        .background(.gray.opacity(0.1))
                    
                    Divider()
                    
                    // 设备选择器
                    DeviceSelector(
                        scale: $scale,
                        lastScale: $lastScale
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(.controlBackgroundColor))
                    
                    Divider()

                    // 模板提供的预览视图
                    b.selectedTemplate.createPreviewView()
                        .frame(maxHeight: .infinity)
                }

                VStack(spacing: 0) {
                    // 模板选择器
                    TemplateSelector()
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                        .background(Color(.controlBackgroundColor))
                    
                    // 模板提供的修改器视图
                    b.selectedTemplate.createModifierView()
                        .frame(maxHeight: .infinity)
                    
                    // 下载按钮区域
                    VStack(spacing: 0) {
                        Divider()
                            .padding(.bottom, 16)
                        
                        BannerDownloadButtons()
                            .environmentObject(BannerProvider.shared)
                            .padding(.horizontal)
                            .padding(.bottom, 16)
                    }
                }
                .frame(maxWidth: geometry.size.width * 0.5)
                .frame(maxHeight: .infinity)
            }
            .environmentObject(BannerProvider.shared)
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
