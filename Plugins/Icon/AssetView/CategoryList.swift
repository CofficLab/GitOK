import MagicCore
import SwiftUI

/**
 * 分类列表组件
 * 负责在左侧显示指定来源下的所有图标分类
 * 支持分类选择、搜索和滚动浏览
 */
struct CategoryList: View {
    let selectedSourceType: IconSourceType
    let selectedCategory: IconCategoryInfo?
    
    @EnvironmentObject var iconProvider: IconProvider
    @State private var categories: [IconCategoryInfo] = []
    @State private var searchText: String = ""
    @State private var isLoading: Bool = false
    
    private var filteredCategories: [IconCategoryInfo] {
        if searchText.isEmpty {
            return categories
        } else {
            return categories.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 搜索框
            SearchBar(text: $searchText)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            
            // 分类列表
            if isLoading {
                VStack {
                    Spacer()
                    ProgressView("加载分类中...")
                        .frame(maxWidth: .infinity)
                    Spacer()
                }
            } else if filteredCategories.isEmpty {
                VStack {
                    Spacer()
                    Text(searchText.isEmpty ? "没有可用的分类" : "没有找到匹配的分类")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredCategories, id: \.id) { category in
                            CategoryRow(
                                category: category,
                                isSelected: selectedCategory?.id == category.id
                            ) {
                                iconProvider.selectCategory(category)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            loadCategories()
        }
        .onChange(of: selectedSourceType) {
            loadCategories()
        }
    }
    
    /// 加载指定来源的分类
    private func loadCategories() {
        isLoading = true
        
        Task {
            let allCategories = await IconRepo.shared.getAllCategories(enableRemote: true)
            let filteredCategories = allCategories.filter { $0.sourceType == selectedSourceType }
            
            await MainActor.run {
                self.categories = filteredCategories.sorted { $0.name < $1.name }
                self.isLoading = false
                
                // 如果当前选中的分类不在新来源中，清空选择
                if let selectedCategory = selectedCategory,
                   !filteredCategories.contains(where: { $0.id == selectedCategory.id }) {
                    iconProvider.clearSelectedCategory()
                }
            }
        }
    }
}

/**
 * 搜索框组件
 * 提供分类搜索功能
 */
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 12))
            
            TextField("搜索分类...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 12))
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(.textBackgroundColor))
        .cornerRadius(6)
    }
}

/**
 * 分类行组件
 * 显示单个分类信息，支持选中状态和点击事件
 */
struct CategoryRow: View {
    let category: IconCategoryInfo
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.name)
                        .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                        .foregroundColor(isSelected ? .accentColor : .primary)
                        .lineLimit(1)
                    
                    Text("\(category.iconCount) 个图标")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 12, weight: .medium))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Rectangle()
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            )
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
    .frame(height: 900)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout().setInitialTab(IconPlugin.label)
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
