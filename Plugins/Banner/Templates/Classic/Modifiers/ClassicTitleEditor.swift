import SwiftUI
import MagicCore

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
        titleText = b.banner.title
        titleColor = b.banner.titleColor ?? .primary
    }
    
    private func updateTitle() {
        try? b.updateBanner { banner in
            banner.title = titleText
        }
    }
    
    private func updateTitleColor() {
        try? b.updateBanner { banner in
            banner.titleColor = titleColor
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
