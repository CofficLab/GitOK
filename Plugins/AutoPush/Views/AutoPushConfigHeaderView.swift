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
                Text(String(localized: "Auto Push Configuration", table: "AutoPush"))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(String(localized: "Manage auto-push settings for project branches.", table: "AutoPush"))
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
            
            Button(String(localized: "Close", table: "AutoPush")) {
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