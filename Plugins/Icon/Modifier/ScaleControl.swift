import SwiftUI


/**
 * 缩放控制组件
 * 提供图标缩放的调整功能
 * 使用本地状态避免频繁更新IconData
 */
struct ScaleControl: View {
    @EnvironmentObject var i: IconProvider
    
    /// 本地状态，避免频繁更新IconData
    @State private var localScale: Double = 1.0
    
    var body: some View {
        GroupBox {
            VStack(spacing: 8) {
                Text("缩放 \(String(format: "%.1f", localScale))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Slider(value: $localScale, in: 0.2...3.0)
                    .onChange(of: localScale) {
                        updateScale(localScale)
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
            localScale = icon.scale ?? 1.0
        }
    }
    
    private func updateScale(_ newValue: Double) {
        if var icon = i.currentData {
            try? icon.updateScale(newValue)
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
