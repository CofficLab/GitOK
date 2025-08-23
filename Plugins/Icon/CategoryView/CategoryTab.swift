import SwiftUI

/**
 * 单个分类标签组件
 * 负责显示分类名称和图标数量，支持选中状态和点击事件
 * 数据流：IconCategory -> CategoryTab
 */
struct CategoryTab: View {
    let category: IconCategory
    
    @EnvironmentObject var iconProvider: IconProvider
    
    /// 判断当前分类是否被选中
    private var isSelected: Bool {
        iconProvider.selectedCategory?.id == category.id
    }
    
    var body: some View {
        Button(action: {
            iconProvider.selectCategory(category)
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
