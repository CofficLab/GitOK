import MagicCore
import OSLog
import SwiftUI

/**
     Banner详情布局视图
     主要的Banner编辑界面，包含顶部的Banner标签页和主要的编辑区域。
 **/
struct BannerDetailLayout: View {
    static let shared = BannerDetailLayout()
    
    @State private var selection: BannerData?
    @State private var showBorder: Bool = false
    @State private var snapshotTapped: Bool = false

    var body: some View {
        HSplitView {
            VStack(spacing: 0) {
                BannerTabsBar(selection: $selection)
                    .background(.gray.opacity(0.1))

                // 主要编辑区域
                if let selectedBanner = selection {
                    BannerEditor()
                        .frame(maxHeight: .infinity)
                } else {
                    EmptyBannerTip()
                }
            }
            .frame(height: .infinity)

            VStack(spacing: 0) {
                if let selectedBanner = selection {
                    GroupBox {
                        HStack {
                            HStack(spacing: 0) {
                                Devices()

                                Spacer()
                            }

                            SnapshotButton()
                                .environmentObject(BannerProvider.shared)
                            
                            BorderToggleButton(showBorder: $showBorder)
                        }
                    }
                    
                    GroupBox {
                        Backgrounds(current: Binding(
                            get: { selectedBanner.backgroundId },
                            set: { _ in }
                        ))
                    }.padding()

                    Spacer()
                } else {
                    EmptyBannerTip()
                }
            }
            .frame(height: .infinity)
            .frame(maxHeight: .infinity)
        }
        .frame(height: .infinity)
        .environmentObject(BannerProvider.shared)
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
