import MagicCore
import SwiftUI

/**
 * 图标盒子视图
 * 负责管理仓库来源选择、分类选择和图标展示的整体布局
 * 顶部显示仓库来源tab，左侧显示分类列表，右侧显示图标网格
 */
struct IconBox: View {
    @EnvironmentObject var iconProvider: IconProvider
    @State private var selectedSourceName: String? = nil
    @State private var availableSources: [IconSourceProtocol] = []

    private var repo = IconRepo.shared

    private var currentSourceIdentifier: String? {
        availableSources.first(where: { $0.sourceName == selectedSourceName })?.sourceIdentifier
    }

    private var currentSourceSupportsCategories: Bool {
        guard let sid = currentSourceIdentifier else { return true }
        return availableSources.first(where: { $0.sourceIdentifier == sid })?.supportsCategories ?? true
    }

    var body: some View {
        VStack(spacing: 0) {
            // 顶部：仓库来源选择tab（使用来源名称）
            SourceTabs(
                selectedSourceName: $selectedSourceName,
                availableSources: availableSources
            )
            .frame(height: 40)

            // 主体内容：左侧分类（可选） + 右侧图标网格
            HStack(spacing: 0) {
                if currentSourceSupportsCategories {
                    // 左侧：分类列表（按来源标识过滤）
                    CategoryList(
                        selectedSourceIdentifier: currentSourceIdentifier,
                        selectedCategory: iconProvider.selectedCategory
                    )
                    .frame(width: 200)
                    .background(Color(.controlBackgroundColor))

                    // 分隔线
                    Divider()
                        .frame(width: 1)
                }

                // 右侧：图标网格
                IconGrid(
                    selectedCategory: iconProvider.selectedCategory,
                    selectedSourceIdentifier: currentSourceIdentifier
                )
            }
        }
        .onAppear {
            loadAvailableSources()
            ensureDefaultSelection()
            // 初始化当前来源标识
            iconProvider.selectedSourceIdentifier = currentSourceIdentifier
        }
        .onChange(of: selectedSourceName, handleSourceChange)
    }

    /// 加载可用的图标来源
    private func loadAvailableSources() {
        availableSources = repo.getAllIconSources()
    }

    /// 确保有默认选择
    private func ensureDefaultSelection() {
        if selectedSourceName == nil {
            selectedSourceName = availableSources.first?.sourceName
        }

        if iconProvider.selectedCategory == nil {
            Task {
                let categories = await repo.getAllCategories(enableRemote: true)
                if let firstCategory = categories.first {
                    await MainActor.run {
                        iconProvider.selectCategory(firstCategory)
                    }
                }
            }
        }
    }
}

// MARK: - Event Handlers

extension IconBox {
    private func handleSourceChange() {
        iconProvider.clearSelectedCategory()

        guard let sid = currentSourceIdentifier else { return }
        
        // 同步当前来源标识到 Provider，供增删操作使用
        iconProvider.selectedSourceIdentifier = sid

        // 若新来源支持分类且当前未选择分类，则选择该来源的第一个分类
        Task {
            let categories = await repo.getAllCategories(enableRemote: true)
            if let first = categories.first(where: { $0.sourceIdentifier == sid }) {
                await MainActor.run {
                    iconProvider.selectCategory(first)
                }
            }
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout().setInitialTab(IconPlugin.label)
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout().setInitialTab(IconPlugin.label)
            .hideSidebar()
    }
    .frame(width: 800)
    .frame(height: 1200)
}
