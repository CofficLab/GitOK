import SwiftUI
import MagicCore

/**
 * 图标内边距控制组件
 * 提供图标内边距的调整功能
 * 使用本地状态避免频繁更新IconData
 */
struct PaddingControl: View {
    @EnvironmentObject var i: IconProvider
    
    /// 本地状态，避免频繁更新IconData
    @State private var localPadding: Double = 0.0
    
    var body: some View {
        GroupBox {
            VStack(spacing: 8) {
                VStack(spacing: 2) {
                    Text("内边距 \(String(format: "%.1f", localPadding))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Xcode 16 格式会自动调整，Xcode 26 格式保持用户设置")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.8))
                }
                Slider(value: $localPadding, in: 0...0.3)
                    .onChange(of: localPadding) {
                        updatePadding(localPadding)
                    }
            }
            .onAppear {
                syncLocalState()
            }
            .onChange(of: i.currentData) { _, newValue in
                syncLocalState()
            }
        }
    }
    
    private func syncLocalState() {
        if let icon = i.currentData {
            localPadding = icon.padding
        }
    }
    
    private func updatePadding(_ newValue: Double) {
        if var icon = i.currentData {
            try? icon.updatePadding(newValue)
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout().setInitialTab(IconPlugin.label)
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 800)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout().setInitialTab(IconPlugin.label)
            .hideSidebar()
    }
    .frame(width: 800)
    .frame(height: 1000)
}
