import SwiftUI
import MagicCore

/**
 * 图标调整工具组件
 * 提供透明度、缩放、圆角等调整功能
 * 使用本地状态避免频繁更新IconData
 */
struct IconAdjustments: View {
    @EnvironmentObject var i: IconProvider
    
    /// 本地状态，避免频繁更新IconData
    @State private var localOpacity: Double = 1.0
    @State private var localScale: Double = 1.0
    @State private var localCornerRadius: Double = 0.0
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                // 透明度控制
                VStack(spacing: 8) {
                    Text("背景透明度 \(String(format: "%.1f", localOpacity))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Slider(value: $localOpacity, in: 0...1)
                        .onChange(of: localOpacity) { newValue in
                            updateOpacity(newValue)
                        }
                }
                
                // 缩放控制
                VStack(spacing: 8) {
                    Text("缩放 \(String(format: "%.1f", localScale))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Slider(value: $localScale, in: 0.2...3.0)
                        .onChange(of: localScale) { newValue in
                            updateScale(newValue)
                        }
                }
                
                // 圆角控制
                VStack(spacing: 8) {
                    Text("圆角 \(Int(localCornerRadius))px")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Slider(value: $localCornerRadius, in: 0...50, step: 1)
                        .onChange(of: localCornerRadius) { newValue in
                            updateCornerRadius(newValue)
                        }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .onAppear {
            syncLocalState()
        }
        .onChange(of: i.currentModel) { _, newValue in
            syncLocalState()
        }
    }
    
    private func syncLocalState() {
        if let icon = i.currentModel {
            localOpacity = icon.opacity
            localScale = icon.scale ?? 1.0
            localCornerRadius = icon.cornerRadius
        }
    }
    
    private func updateOpacity(_ newValue: Double) {
        if var icon = i.currentModel {
            try? icon.updateOpacity(newValue)
        }
    }
    
    private func updateScale(_ newValue: Double) {
        if var icon = i.currentModel {
            try? icon.updateScale(newValue)
        }
    }
    
    private func updateCornerRadius(_ newValue: Double) {
        if var icon = i.currentModel {
            try? icon.updateCornerRadius(newValue)
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout().setInitialTab("Icon")
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 800)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout().setInitialTab("Icon")
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
