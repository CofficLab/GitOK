import SwiftUI

/// 通用状态栏 Tile：统一 hover 背景、内边距与形状。
struct StatusBarTile<Content: View>: View {
    @State private var hovered = false

    let icon: String?
    let onTap: (() -> Void)?
    let content: () -> Content

    init(icon: String? = nil, onTap: (() -> Void)? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.icon = icon
        self.onTap = onTap
        self.content = content
    }

    var body: some View {
        HStack {
            if let icon {
                Image(systemName: icon)
            }
            content()
                .font(.footnote)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .frame(maxHeight: .infinity, alignment: .center)
        .clipShape(RoundedRectangle(cornerRadius: 0))
        .background(hovered ? Color(.controlAccentColor).opacity(0.2) : .clear)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
        .onHover { hovering in
            hovered = hovering
        }
    }
}

extension StatusBarTile where Content == EmptyView {
    init(icon: String? = nil, onTap: (() -> Void)? = nil) {
        self.init(icon: icon, onTap: onTap) { EmptyView() }
    }
}

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

