import MagicCore
import OSLog
import SwiftUI

/**
     Banner详情布局视图
     主要的Banner编辑界面，包含顶部的Banner标签页和主要的编辑区域。
 **/
struct BannerDetailLayout: View {
    @EnvironmentObject var b: BannerProvider
    @EnvironmentObject var g: DataProvider
    @EnvironmentObject var m: MagicMessageProvider
    @State private var selection: BannerData?

    var body: some View {
        HSplitView {
            VStack(spacing: 0) {
                BannerTabsBar(selection: $selection)
                    .background(.gray.opacity(0.1))

                // 主要编辑区域
                if let selectedBanner = selection {
                    BannerEditor(banner: Binding(
                        get: { selectedBanner },
                        set: { newValue in
                            selection = newValue
                            b.setBanner(newValue)

                            // 保存到磁盘
                            do {
                                try newValue.saveToDisk()
                            } catch {
                                m.error(error.localizedDescription)
                            }
                        }
                    ))
                    .frame(maxHeight: .infinity)
                } else {
                    EmptyBannerTip()
                }
            }
            .frame(height: .infinity)
            .onChange(of: selection) { _, newValue in
                if let newValue = newValue {
                    b.setBanner(newValue)
                }
            }

            VStack(spacing: 0) {
                if let selectedBanner = selection {
                    
                    GroupBox {
                        Backgrounds(current: Binding(
                            get: { selectedBanner.backgroundId },
                            set: { _ in }
                        ))
                    }.padding()
                    
                    
                } else {
                    EmptyBannerTip()
                }
            }
            .frame(height: .infinity)
            .frame(maxHeight: .infinity)
            .onChange(of: selection) { _, newValue in
                if let newValue = newValue {
                    b.setBanner(newValue)
                }
            }
        }
        .frame(height: .infinity)
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
            .hideSidebar()
    }
    .frame(width: 800)
    .frame(height: 1000)
}
