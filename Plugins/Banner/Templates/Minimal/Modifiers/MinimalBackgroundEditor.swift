import SwiftUI
import MagicAlert
import MagicUI

/**
 经典模板的背景编辑器
 专门为经典布局定制的背景设置组件
 */
struct MinimalBackgroundEditor: View {
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
    }
    
    private func loadCurrentBackground() {
        if let minimalData = b.banner.minimalData {
            selectedBackgroundId = minimalData.backgroundId
        }
    }
    
    private func selectBackground(_ backgroundId: String) {
        selectedBackgroundId = backgroundId
        
        try? b.updateBanner { banner in
            var minimalData = banner.minimalData ?? MinimalBannerData()
            minimalData.backgroundId = backgroundId
            banner.minimalData = minimalData
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
