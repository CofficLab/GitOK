import SwiftUI
import MagicCore

/**
 简约模板的标题编辑器
 专门为简约布局定制的标题编辑组件
 */
struct MinimalTitleEditor: View {
    @EnvironmentObject var b: BannerProvider
    @EnvironmentObject var m: MagicMessageProvider
    
    @State private var minimalData: MinimalBannerData = MinimalBannerData()
    
    var body: some View {
        GroupBox("主标题") {
            VStack(spacing: 12) {
                // 标题输入
                TextField("输入主标题", text: $minimalData.title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.title2)
                    .onChange(of: minimalData.title) {
                        saveData()
                    }
                
                // 字体大小调节
                HStack {
                    Text("字体大小")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Slider(
                        value: $minimalData.titleSize,
                        in: 24.0...72.0,
                        step: 2.0
                    )
                    .onChange(of: minimalData.titleSize) { _ in
                        saveData()
                    }
                    
                    Text("\(Int(minimalData.titleSize))pt")
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
        // 从当前Banner数据恢复简约模板数据
        let template = MinimalBannerTemplate()
        minimalData = template.restoreData(from: b.banner) as! MinimalBannerData
    }
    
    private func saveData() {
        do {
            let template = MinimalBannerTemplate()
            try b.updateBanner { banner in
                try template.saveData(minimalData, to: &banner)
            }
            
            try BannerRepo.shared.saveBanner(b.banner)
        } catch {
            m.error(error, title: "保存数据失败")
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
    }
    .frame(width: 800)
    .frame(height: 1000)
}
