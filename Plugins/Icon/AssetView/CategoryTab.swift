import SwiftUI

/**
 * 统一分类标签页组件
 * 负责显示单个分类标签，支持选中状态和点击事件
 * 数据流：IconCategory -> UnifiedCategoryTab
 */
struct CategoryTab: View {
    let category: IconCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            onTap()
        }) {
            VStack(spacing: 4) {
                Text(category.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            .foregroundColor(isSelected ? .accentColor : .primary)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
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
