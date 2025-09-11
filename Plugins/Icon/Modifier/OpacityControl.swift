import SwiftUI
import MagicCore

/**
 * 透明度控制组件
 * 提供背景透明度的调整功能
 * 使用本地状态避免频繁更新IconData
 */
struct OpacityControl: View {
    @EnvironmentObject var i: IconProvider
    
    /// 本地状态，避免频繁更新IconData
    @State private var localOpacity: Double = 1.0
    
    var body: some View {
        GroupBox {
            VStack(spacing: 8) {
                Text("背景透明度 \(String(format: "%.1f", localOpacity))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Slider(value: $localOpacity, in: 0...1)
                    .onChange(of: localOpacity) {
                        updateOpacity(localOpacity)
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
            localOpacity = icon.opacity
        }
    }
    
    private func updateOpacity(_ newValue: Double) {
        if var icon = i.currentData {
            try? icon.updateOpacity(newValue)
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
    .frame(width: 1200)
    .frame(height: 1200)
}
