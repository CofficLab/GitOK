import SwiftUI
import MagicCore

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
            VStack(spacing: 12) {
                // 背景选择网格
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 60, maximum: 80), spacing: 8)
                ], spacing: 8) {
                    ForEach(1...12, id: \.self) { backgroundId in
                        BackgroundPreview(
                            backgroundId: "\(backgroundId)",
                            isSelected: selectedBackgroundId == "\(backgroundId)",
                            onSelect: {
                                selectBackground("\(backgroundId)")
                            }
                        )
                    }
                }
                .padding(8)
            }
            .padding(8)
        }
        .onAppear {
            loadCurrentBackground()
        }
    }
    
    private func loadCurrentBackground() {
        selectedBackgroundId = b.banner.backgroundId
    }
    
    private func selectBackground(_ backgroundId: String) {
        selectedBackgroundId = backgroundId
        
        try? b.updateBanner { banner in
            banner.backgroundId = backgroundId
        }
    }
}

/**
 背景预览组件
 */
private struct BackgroundPreview: View {
    let backgroundId: String
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            RoundedRectangle(cornerRadius: 6)
                .fill(backgroundGradient)
                .frame(width: 60, height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                )
                .overlay(
                    Text(backgroundId)
                        .font(.caption2)
                        .foregroundColor(.white)
                        .fontWeight(.medium)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private var backgroundGradient: LinearGradient {
        switch backgroundId {
        case "1":
            return LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "2":
            return LinearGradient(colors: [.green, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "3":
            return LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "4":
            return LinearGradient(colors: [.pink, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "5":
            return LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "6":
            return LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [.gray, .black], startPoint: .topLeading, endPoint: .bottomTrailing)
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
