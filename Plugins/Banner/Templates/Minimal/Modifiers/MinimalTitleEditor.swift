import SwiftUI
import MagicCore

/**
 简约模板的标题编辑器
 专门为简约布局定制的标题编辑组件
 */
struct MinimalTitleEditor: View {
    @EnvironmentObject var b: BannerProvider
    @EnvironmentObject var m: MagicMessageProvider
    
    @State private var titleText: String = ""
    @State private var titleSize: Double = 36.0
    
    var body: some View {
        GroupBox("主标题") {
            VStack(spacing: 12) {
                // 标题输入
                TextField("输入主标题", text: $titleText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.title2)
                    .onChange(of: titleText) {
                        updateTitle()
                    }
                
                // 字体大小调节
                HStack {
                    Text("字体大小")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Slider(
                        value: $titleSize,
                        in: 24.0...72.0,
                        step: 2.0
                    )
                    .onChange(of: titleSize) { _ in
                        updateTitleSize()
                    }
                    
                    Text("\(Int(titleSize))pt")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .trailing)
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
        // 简约模板可能有自己的字体大小设置
    }
    
    private func updateTitle() {
        var updatedBanner = b.banner
        updatedBanner.title = titleText
        
        do {
            try BannerRepo.shared.saveBanner(updatedBanner)
            b.banner = updatedBanner
        } catch {
            m.error(error, title: "保存标题失败")
        }
    }
    
    private func updateTitleSize() {
        // 简约模板特有的字体大小更新逻辑
        // 这里可以扩展为保存到模板特定的数据结构中
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
    }
    .frame(width: 800)
    .frame(height: 1000)
}
