import SwiftUI
import MagicCore

/**
 * 图标调整工具组件
 * 整合透明度和缩放调整功能，提供统一的图标参数调整界面
 */
struct IconAdjustments: View {
    @EnvironmentObject var i: IconProvider
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                // 透明度控制
                VStack(spacing: 8) {
                    Text("透明度 \(String(format: "%.1f", i.currentModel?.opacity ?? 1.0))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Slider(value: Binding(
                        get: { i.currentModel?.opacity ?? 1.0 },
                        set: { newValue in
                            if var icon = i.currentModel {
                                try? icon.updateOpacity(newValue)
                            }
                        }
                    ), in: 0...1)
                }
                
                // 缩放控制
                VStack(spacing: 8) {
                    Text("缩放 \(String(format: "%.1f", i.currentModel?.scale ?? 1.0))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Slider(value: Binding(
                        get: { i.currentModel?.scale ?? 1.0 },
                        set: { newValue in
                            if var icon = i.currentModel {
                                try? icon.updateScale(newValue)
                            }
                        }
                    ), in: 0.1...2)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout().setInitialTab("Icon")
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout().setInitialTab("Icon")
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
