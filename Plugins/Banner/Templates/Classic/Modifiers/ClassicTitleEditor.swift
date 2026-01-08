import SwiftUI

import MagicAlert

/**
 经典模板的标题编辑器
 专门为经典布局定制的标题编辑组件
 */
struct ClassicTitleEditor: View {
    @EnvironmentObject var b: BannerProvider
    @EnvironmentObject var m: MagicMessageProvider
    
    @State private var titleText: String = ""
    @State private var titleColor: Color = .primary
    
    var body: some View {
        GroupBox("标题设置") {
            VStack(spacing: 12) {
                // 标题输入
                HStack {
                    Text("标题")
                        .frame(width: 60, alignment: .leading)
                    
                    TextField("输入标题", text: $titleText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: titleText) {
                            updateTitle()
                        }
                }
                
                // 标题颜色选择
                HStack {
                    Text("颜色")
                        .frame(width: 60, alignment: .leading)
                    
                    ColorPicker("选择颜色", selection: $titleColor)
                        .labelsHidden()
                        .onChange(of: titleColor) {
                            updateTitleColor()
                        }
                    
                    Spacer()
                }
            }
            .padding(8)
        }
        .onAppear {
            loadCurrentValues()
        }
    }
    
    private func loadCurrentValues() {
        if let classicData = b.banner.classicData {
            titleText = classicData.title
            titleColor = classicData.titleColor ?? .primary
        }
    }
    
    private func updateTitle() {
        try? b.updateBanner { banner in
            var classicData = banner.classicData ?? ClassicBannerData()
            classicData.title = titleText
            banner.classicData = classicData
        }
    }
    
    private func updateTitleColor() {
        try? b.updateBanner { banner in
            var classicData = banner.classicData ?? ClassicBannerData()
            classicData.titleColor = titleColor
            banner.classicData = classicData
        }
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .setInitialTab(BannerPlugin.label)
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .setInitialTab(BannerPlugin.label)
        .hideTabPicker()
        .inRootView()
        .frame(width: 800)
        .frame(height: 1000)
}
