import SwiftUI
import MagicCore

// MARK: - 分类标签页组件
struct CategoryTabs: View {
    @EnvironmentObject var iconProvider: IconProvider
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(iconProvider.categories, id: \.name) { category in
                    CategoryTab(
                        title: category.name,
                        isSelected: iconProvider.selectedCategory?.name == category.name,
                        iconCount: category.iconCount
                    ) {
                        iconProvider.selectCategory(category.name)
                    }
                }
            }
            .padding(.horizontal)
        }
        .onAppear {
            // 确保分类列表是最新的
            iconProvider.refreshCategories()
        }
    }
}

// MARK: - 单个分类标签
struct CategoryTab: View {
    let title: String
    let isSelected: Bool
    let iconCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title.uppercased())
                    .font(.caption)
                    .fontWeight(.medium)
                Text("\(iconCount)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            .foregroundColor(isSelected ? .accentColor : .primary)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 分类图标网格
struct CategoryIconGrid: View {
    let category: String
    let gridItems: [GridItem]
    let onIconSelected: (Int) -> Void
    
    @EnvironmentObject var iconProvider: IconProvider
    
    var body: some View {
        LazyVGrid(columns: gridItems, spacing: 12) {
            if let categoryModel = iconProvider.getCategory(byName: category) {
                ForEach(categoryModel.iconIds, id: \.self) { iconId in
                    CategoryIconItem(
                        category: category,
                        iconId: iconId,
                        onTap: {
                            onIconSelected(iconId)
                        }
                    )
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - 分类图标项
struct CategoryIconItem: View {
    let category: String
    let iconId: Int
    let onTap: () -> Void
    
    @EnvironmentObject var iconProvider: IconProvider
    @State private var image = Image(systemName: "photo")
    @State private var isHovered = false
    
    /// 判断当前图标是否被选中
    private var isSelected: Bool {
        iconProvider.selectedIconId == iconId
    }
    
    var body: some View {
        image
            .resizable()
            .frame(width: 60, height: 60)
            .background(
                Group {
                    if isSelected {
                        // 选中状态：蓝色背景
                        Color.accentColor.opacity(0.3)
                    } else if isHovered {
                        // 悬停状态：浅色背景
                        Color.accentColor.opacity(0.1)
                    } else {
                        // 默认状态：透明背景
                        Color.clear
                    }
                }
            )
            .overlay(
                // 选中状态显示蓝色边框
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .cornerRadius(8)
            .onTapGesture {
                onTap()
            }
            .onHover { hovering in
                isHovered = hovering
            }
            .onAppear {
                DispatchQueue.global().async {
                    let thumbnail = IconPng.getThumbnail(category: category, iconId: iconId)
                    DispatchQueue.main.async {
                        self.image = thumbnail
                    }
                }
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
