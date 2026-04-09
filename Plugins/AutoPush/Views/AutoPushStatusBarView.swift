import SwiftUI

/// 状态栏视图：显示操作状态消息
struct AutoPushStatusBarView: View {
    let message: String?
    
    var body: some View {
        if let message = message {
            HStack {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            .overlay(separatorLine, alignment: .top)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
    
    private var separatorLine: some View {
        Rectangle()
            .frame(height: 1)
            .foregroundColor(Color(NSColor.separatorColor))
    }
}

#Preview("AutoPushStatusBarView") {
    VStack {
        Spacer()
        AutoPushStatusBarView(message: "已启用自动推送：TestProject/main")
    }
    .frame(width: 500, height: 100)
}