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

    @State private var selection: BannerData?

    var body: some View {
        GeometryReader { geometry in
            HSplitView {
                VStack(spacing: 0) {
                    BannerTabsBar(selection: $selection)
                        .background(.gray.opacity(0.1))

                    BannerEditor()
                        .frame(maxHeight: .infinity)
                }

                VStack(spacing: 0) {
                    // 设备选择器
                    GroupBox("设备类型") {
                        HStack {
                            Devices()
                            Spacer()
                        }
                    }
                    .padding(.horizontal)
                    
                    // 编辑器区域
                    ScrollView {
                        VStack(spacing: 16) {
                            TitleEditor()
                            SubTitleEditor()
                            FeaturesEditor()
                            ImageEditor()
                            
                            GroupBox("背景设置") {
                                Backgrounds()
                            }
                            
                            OpacityEditor()
                        }
                        .padding()
                    }
                    
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
            .hideProjectActions()
            .hideTabPicker()
            .hideSidebar()
    }
    .frame(width: 800)
    .frame(height: 1000)
}
