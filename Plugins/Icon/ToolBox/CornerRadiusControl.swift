import SwiftUI
import MagicCore

/**
 * 圆角控制组件
 * 提供图标圆角的调整功能
 * 使用本地状态避免频繁更新IconData
 */
struct CornerRadiusControl: View {
    @EnvironmentObject var i: IconProvider
    
    /// 本地状态，避免频繁更新IconData
    @State private var localCornerRadius: Double = 0.0
    
    var body: some View {
        VStack(spacing: 8) {
            Text("圆角 \(Int(localCornerRadius))px")
                .font(.caption)
                .foregroundColor(.secondary)
            Slider(value: $localCornerRadius, in: 0...50, step: 1)
                .onChange(of: localCornerRadius) {
                    updateCornerRadius(localCornerRadius)
                }
        }
        .onAppear {
            syncLocalState()
        }
        .onChange(of: i.currentData) { _, newValue in
            syncLocalState()
        }
    }
    
    private func syncLocalState() {
        if let icon = i.currentData {
            localCornerRadius = icon.cornerRadius
        }
    }
    
    private func updateCornerRadius(_ newValue: Double) {
        if var icon = i.currentData {
            try? icon.updateCornerRadius(newValue)
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
