import AppKit
import GitOKCoreKit
import SwiftUI

/**
 * 分类列表组件
 * 负责在左侧显示指定来源下的所有图标分类
 * 支持分类选择、搜索和滚动浏览
 */
struct CategoryList: View {
    let selectedSourceIdentifier: String?
    let selectedCategory: IconCategory?

    @EnvironmentObject var iconProvider: IconProvider
    @State private var categories: [IconCategory] = []
    @State private var searchText: String = ""
    @State private var isLoading: Bool = false
    @State private var error: Error? = nil

    private var currentSourceSupportsMutations: Bool {
        guard let sid = selectedSourceIdentifier else { return false }
        return IconRepo.shared.getAllIconSources().first(where: { $0.sourceIdentifier == sid })?.supportsMutations ?? false
    }

    private var filteredCategories: [IconCategory] {
        let list = categories.filter { category in
            guard let sid = selectedSourceIdentifier else { return true }
            return category.sourceIdentifier == sid
        }
        if searchText.isEmpty { return list }
        return list.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 搜索框
            SearchBar(text: $searchText)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            // 分类列表
            if isLoading {
                AppLoadingOverlay(message: IconLocalization.string("loading-categories"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = error {
                VStack {
                    error.makeView().padding()
                    AppButton(
                        IconLocalization.string("open-cache-directory"),
                        systemImage: "folder",
                        style: .secondary,
                        size: .small
                    ) {
                        URL.temp.openHttpCacheDirectory()
                    }
                }
            } else if filteredCategories.isEmpty {
                AppEmptyState(
                    icon: "folder",
                    title: searchText.isEmpty ? IconLocalization.string("no-categories-available") : IconLocalization.string("no-matching-categories")
                )
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
        .onAppear { loadCategories() }
        .onChange(of: selectedSourceIdentifier) {
            loadCategories()
        }
    }

    /// 加载所有分类
    private func loadCategories() {
        isLoading = true
        Task {
            let allCategories: [IconCategory]

            if let sid = selectedSourceIdentifier {
                // 只加载指定来源的分类
                do {
                    allCategories = try await IconRepo.shared.getAllCategories(for: sid)
                    await MainActor.run { self.error = nil }
                } catch {
                    allCategories = []
                    await MainActor.run { self.error = error }
                }
            } else {
                // 没有指定来源时，分类列表为空
                allCategories = []
                await MainActor.run { self.error = nil }
            }

            await MainActor.run {
                self.categories = allCategories.sorted { $0.name < $1.name }
                self.isLoading = false

                if let selectedCategory = selectedCategory,
                   let sid = selectedSourceIdentifier,
                   selectedCategory.sourceIdentifier != sid {
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
        AppSearchBar(text: $text, placeholder: IconLocalization.string("search-categories"))
    }
}

/**
 * 分类行组件
 * 显示单个分类信息，支持选中状态和点击事件
 */
struct CategoryRow: View {
    let category: IconCategory
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        AppListRow(isSelected: isSelected, action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.name)
                        .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                        .foregroundColor(isSelected ? .accentColor : .primary)
                        .lineLimit(1)

                    Text(IconLocalization.string("icon-count").replacingOccurrences(of: "%lld", with: "\(category.iconCount)"))
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
        }
    }
}
