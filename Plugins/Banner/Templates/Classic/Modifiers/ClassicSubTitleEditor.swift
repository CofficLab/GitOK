import SwiftUI
import MagicCore

/**
 经典模板的副标题编辑器
 专门为经典布局定制的副标题编辑组件
 */
struct ClassicSubTitleEditor: View {
    @EnvironmentObject var b: BannerProvider
    @EnvironmentObject var m: MagicMessageProvider
    
    @State private var subTitleText: String = ""
    @State private var subTitleColor: Color = .secondary
    
    var body: some View {
        GroupBox("副标题设置") {
            VStack(spacing: 12) {
                // 副标题输入
                HStack {
                    Text("副标题")
                        .frame(width: 60, alignment: .leading)
                    
                    TextField("输入副标题", text: $subTitleText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: subTitleText) {
                            updateSubTitle()
                        }
                }
                
                // 副标题颜色选择
                HStack {
                    Text("颜色")
                        .frame(width: 60, alignment: .leading)
                    
                    ColorPicker("选择颜色", selection: $subTitleColor)
                        .labelsHidden()
                        .onChange(of: subTitleColor) {
                            updateSubTitleColor()
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
        subTitleText = b.banner.subTitle
        subTitleColor = b.banner.subTitleColor ?? .secondary
    }
    
    private func updateSubTitle() {
        var updatedBanner = b.banner
        updatedBanner.subTitle = subTitleText
        
        do {
            try BannerRepo.shared.saveBanner(updatedBanner)
            b.banner = updatedBanner
        } catch {
            m.error("保存副标题失败: \(error.localizedDescription)")
        }
    }
    
    private func updateSubTitleColor() {
        var updatedBanner = b.banner
        updatedBanner.subTitleColor = subTitleColor
        
        do {
            try BannerRepo.shared.saveBanner(updatedBanner)
            b.banner = updatedBanner
        } catch {
            m.error("保存副标题颜色失败: \(error.localizedDescription)")
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
