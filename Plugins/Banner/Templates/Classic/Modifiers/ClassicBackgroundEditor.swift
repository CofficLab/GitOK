import SwiftUI
import MagicUI
import MagicAlert

/**
 经典模板的背景编辑器
 专门为经典布局定制的背景设置组件
 */
struct ClassicBackgroundEditor: View {
    @EnvironmentObject var b: BannerProvider
    @EnvironmentObject var m: MagicMessageProvider
    
    @State private var selectedBackgroundId: String = "1"
    
    var body: some View {
        GroupBox("背景设置") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(0 ..< MagicBackgroundGroup.all.count, id: \.self) { index in
                        let gradient = MagicBackgroundGroup.all[index]
                        BackgroundPreview(
                            gradient: gradient,
                            isSelected: selectedBackgroundId == gradient.rawValue,
                            onSelect: {
                                selectBackground(gradient.rawValue)
                            }
                        )
                        .frame(width: 60, height: 40)
                    }
                }
                .padding(8)
            }
        }
        .onAppear {
            loadCurrentBackground()
        }
        .onChange(of: b.banner.id) {
            loadCurrentBackground()
        }
    }
    
    private func loadCurrentBackground() {
        if let classicData = b.banner.classicData {
            selectedBackgroundId = classicData.backgroundId
        }
    }
    
    private func selectBackground(_ backgroundId: String) {
        selectedBackgroundId = backgroundId
        
        do {
            try b.updateBanner { banner in
                var classicData = banner.classicData ?? ClassicBannerData()
                classicData.backgroundId = backgroundId
                banner.classicData = classicData
            }
        } catch {
            m.error("更新背景失败: \(error.localizedDescription)")
        }
    }
}

/**
 背景预览组件
 */
private struct BackgroundPreview: View {
    let gradient: MagicBackgroundGroup.GradientName
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            ZStack {
                MagicBackgroundGroup(for: gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                
                if isSelected {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.accentColor, lineWidth: 2)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
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

