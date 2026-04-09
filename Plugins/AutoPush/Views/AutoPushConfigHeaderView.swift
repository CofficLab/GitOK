import SwiftUI

/// 自动推送配置视图的标题栏
struct AutoPushConfigHeaderView: View {
    let isLoading: Bool
    let onClose: () -> Void
    
    var body: some View {
        HStack {
            headerTitle
            Spacer()
            headerActions
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(separatorLine, alignment: .bottom)
    }
    
    // MARK: - Subviews
    
    private var headerTitle: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.up.circle")
                .foregroundColor(.blue)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("自动推送配置")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("管理项目分支的自动推送设置")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var headerActions: some View {
        HStack(spacing: 12) {
            if isLoading {
                ProgressView()
                    .controlSize(.small)
            }
            
            Button("关闭") {
                onClose()
            }
            .keyboardShortcut(.cancelAction)
        }
    }
    
    private var separatorLine: some View {
        Rectangle()
            .frame(height: 1)
            .foregroundColor(Color(NSColor.separatorColor))
    }
}

#Preview("AutoPushConfigHeaderView") {
    AutoPushConfigHeaderView(
        isLoading: false,
        onClose: {}
    )
    .frame(width: 500)
}