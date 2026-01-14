import SwiftUI

/// Git 用户配置行视图组件
/// 显示单个用户配置项，支持选择和交互
struct GitUserConfigRowView: View, SuperLog {
    /// 日志标识符
    nonisolated static let emoji = "👤"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// 用户配置对象
    let config: GitUserConfig

    /// 当前选中的配置
    let selectedConfig: GitUserConfig?

    /// 点击回调
    let onTap: (GitUserConfig) -> Void
    
    @State private var isHovered = false
    @State private var isTapped = false
    
    private var isSelected: Bool {
        selectedConfig?.id == config.id
    }
    
    private var backgroundColorForState: Color {
        if isTapped {
            return isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.15)
        } else if isHovered {
            return isSelected ? Color.blue.opacity(0.15) : Color.gray.opacity(0.08)
        } else if isSelected {
            return Color.blue.opacity(0.1)
        } else {
            return Color.clear
        }
    }
    
    private var borderColorForState: Color {
        if isTapped {
            return isSelected ? Color.blue.opacity(0.8) : Color.gray.opacity(0.6)
        } else if isHovered {
            return isSelected ? Color.blue.opacity(0.9) : Color.gray.opacity(0.5)
        } else if isSelected {
            return Color.blue
        } else {
            return Color.gray.opacity(0.3)
        }
    }
    
    private var strokeWidthForState: CGFloat {
        if isTapped {
            return 1.5
        } else if isHovered {
            return 1.2
        } else {
            return 1.0
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(config.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(config.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if config.isDefault {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColorForState)
                .animation(.easeInOut(duration: 0.2), value: isSelected)
                .animation(.easeInOut(duration: 0.15), value: isHovered)
                .animation(.easeInOut(duration: 0.1), value: isTapped)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColorForState, lineWidth: strokeWidthForState)
                .animation(.easeInOut(duration: 0.2), value: isSelected)
                .animation(.easeInOut(duration: 0.15), value: isHovered)
                .animation(.easeInOut(duration: 0.1), value: isTapped)
        )
        .scaleEffect(isTapped ? 0.98 : (isHovered ? 1.02 : 1.0))
        .animation(.interpolatingSpring(stiffness: 400, damping: 20), value: isTapped)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            // 立即执行选中逻辑
            onTap(config)
            
            // 然后执行视觉反馈动画
            withAnimation(.interpolatingSpring(stiffness: 600, damping: 25)) {
                isTapped = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.interpolatingSpring(stiffness: 400, damping: 20)) {
                    isTapped = false
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
} 