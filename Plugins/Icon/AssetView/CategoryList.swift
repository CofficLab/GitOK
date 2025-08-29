import AppKit
import MagicCore
import SwiftUI

/**
 * 分类列表组件
 * 负责在左侧显示指定来源下的所有图标分类
 * 支持分类选择、搜索和滚动浏览
 */
struct CategoryList: View {
    let selectedSourceIdentifier: String?
    let selectedCategory: IconCategoryInfo?

    @EnvironmentObject var iconProvider: IconProvider
    @State private var categories: [IconCategoryInfo] = []
    @State private var searchText: String = ""
    @State private var isLoading: Bool = false

    private var currentSourceSupportsMutations: Bool {
        guard let sid = selectedSourceIdentifier else { return false }
        return IconRepo.shared.getAllIconSources().first(where: { $0.sourceIdentifier == sid })?.supportsMutations ?? false
    }

    private var filteredCategories: [IconCategoryInfo] {
        let list = categories.filter { category in
            guard let sid = selectedSourceIdentifier else { return true }
            return category.sourceIdentifier == sid
        }
        if searchText.isEmpty { return list }
        return list.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 顶部工具条（当来源支持增删时显示）
            if currentSourceSupportsMutations {
                HStack(spacing: 8) {
                    Button("添加图标…") { addImagesViaPanel() }
                        .buttonStyle(.bordered)
                    Button("删除图标…") { deleteImagesViaPanel() }
                        .buttonStyle(.bordered)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
            }

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
                .onAppear { print("[CategoryList] filtered empty. selectedSourceIdentifier=\(selectedSourceIdentifier ?? "nil"), total=\(categories.count)") }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredCategories, id: \.id) { category in
                            CategoryRow(
                                category: category,
                                isSelected: selectedCategory?.id == category.id
                            ) {
                                print("[CategoryList] select category: \(category.id) from \(category.sourceIdentifier)")
                                iconProvider.selectCategory(category)
                            }
                        }
                    }
                }
            }
        }
        .onAppear { loadCategories() }
        .onChange(of: selectedSourceIdentifier) { _ in
            print("[CategoryList] selectedSourceIdentifier changed to: \(selectedSourceIdentifier ?? "nil")")
            loadCategories()
        }
    }

    /// 通过文件选择器添加图片
    private func addImagesViaPanel() {
        guard currentSourceSupportsMutations else { return }
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedFileTypes = ["png", "svg", "jpg", "jpeg", "gif", "webp"]
        panel.begin { response in
            guard response == .OK else { return }
            let urls = panel.urls
            Task { @MainActor in
                var okCount = 0
                for url in urls {
                    if let data = try? Data(contentsOf: url) {
                        if iconProvider.addImageToProjectLibrary(data: data, filename: url.lastPathComponent) {
                            okCount += 1
                        }
                    }
                }
                print("[CategoryList] addImagesViaPanel done: \(okCount)/\(urls.count)")
                loadCategories()
            }
        }
    }

    /// 通过文件选择器删除图片（选择要删除的文件名）
    private func deleteImagesViaPanel() {
        guard currentSourceSupportsMutations else { return }
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedFileTypes = ["png", "svg", "jpg", "jpeg", "gif", "webp"]
        panel.begin { response in
            guard response == .OK else { return }
            let urls = panel.urls
            Task { @MainActor in
                var okCount = 0
                for url in urls {
                    if iconProvider.deleteImageFromProjectLibrary(filename: url.lastPathComponent) {
                        okCount += 1
                    }
                }
                print("[CategoryList] deleteImagesViaPanel done: \(okCount)/\(urls.count)")
                loadCategories()
            }
        }
    }

    /// 加载所有分类
    private func loadCategories() {
        isLoading = true
        Task {
            print("[CategoryList] loading categories...")
            let allCategories = await IconRepo.shared.getAllCategories(enableRemote: true)
            await MainActor.run {
                self.categories = allCategories.sorted { $0.name < $1.name }
                self.isLoading = false
                print("[CategoryList] loaded categories: total=\(self.categories.count)")
                if let sid = selectedSourceIdentifier {
                    let count = self.categories.filter { $0.sourceIdentifier == sid }.count
                    print("[CategoryList] filter by sid=\(sid) -> count=\(count)")
                }

                if let selectedCategory = selectedCategory,
                   let sid = selectedSourceIdentifier,
                   selectedCategory.sourceIdentifier != sid {
                    print("[CategoryList] clearSelectedCategory due to sid mismatch")
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Rectangle()
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.primary.opacity(0.01))
            )
        }
        .contentShape(Rectangle())
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(IconPlugin.label)
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 900)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(IconPlugin.label)
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
