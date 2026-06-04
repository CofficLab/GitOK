
import SwiftUI
import GitOKCoreKit
import GitOKUI

/**
 * 图标网格视图
 * 负责显示图标网格布局和加载状态
 * 支持动态列数调整和滚动加载，优化了左右分栏布局
 */
struct IconGrid: View {
    @EnvironmentObject var iconProvider: IconProvider

    @State private var gridItems: [GridItem] = Array(repeating: .init(.flexible()), count: 8)
    @State private var iconAssets: [IconAsset] = []
    @State private var isLoading: Bool = false

    let selectedCategory: IconCategory?
    let selectedSourceIdentifier: String?

    init(selectedCategory: IconCategory?, selectedSourceIdentifier: String?) {
        self.selectedCategory = selectedCategory
        self.selectedSourceIdentifier = selectedSourceIdentifier
    }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // 分类标题（若来源不支持分类或分类与来源不匹配，则显示来源名）
                if let sid = selectedSourceIdentifier,
                   let source = IconRepo.shared.getAllIconSources().first(where: { $0.sourceIdentifier == sid }),
                   source.supportsCategories,
                   let category = selectedCategory,
                   category.sourceIdentifier == sid {
                    VStack(spacing: 8) {
                        HStack {
                            Text(category.name)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            Spacer()
                            Text(IconLocalization.string("icon-count").replacingOccurrences(of: "%lld", with: "\(iconAssets.count)"))
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }

                        // 右侧：在分类标题下方放置添加/删除按钮（当来源支持增删时显示）
                        if IconRepo.shared.getAllIconSources().first(where: { $0.sourceIdentifier == sid })?.supportsMutations == true {
                            HStack(spacing: 8) {
                                AppButton(
                                    IconLocalization.string("add-icon-button"),
                                    systemImage: "plus",
                                    style: .secondary,
                                    size: .small
                                ) { addImagesViaPanel() }
                                AppButton(
                                    IconLocalization.string("delete-icon-button"),
                                    systemImage: "trash",
                                    style: .destructive,
                                    size: .small
                                ) { deleteImagesViaPanel() }
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .gitOKUISurface(style: .toolbar, cornerRadius: 0)
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Color(.separatorColor)),
                        alignment: .bottom
                    )
                } else if let sid = selectedSourceIdentifier,
                          let source = IconRepo.shared.getAllIconSources().first(where: { $0.sourceIdentifier == sid }) {
                    VStack(spacing: 8) {
                        HStack {
                            Text(source.sourceName)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            Spacer()
                            if source.supportsMutations {
                                AppButton(
                                    IconLocalization.string("add-image-button"),
                                    systemImage: "plus",
                                    style: .secondary,
                                    size: .small
                                ) { addImagesViaPanel() }
                                AppButton(
                                    IconLocalization.string("delete-selected-button"),
                                    systemImage: "trash",
                                    style: .destructive,
                                    size: .small
                                ) { deleteSelectedImage() }
                                    .disabled(!canDeleteSelected(in: sid))
                            }
                            Text(IconLocalization.string("icon-count").replacingOccurrences(of: "%lld", with: "\(iconAssets.count)"))
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .gitOKUISurface(style: .toolbar, cornerRadius: 0)
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Color(.separatorColor)),
                        alignment: .bottom
                    )
                }

                // 图标网格内容
                if isLoading {
                    AppLoadingOverlay(message: IconLocalization.string("loading-icons"))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if iconAssets.isEmpty {
                    let shouldSelectPrompt = selectedSourceIdentifier == nil
                    AppEmptyState(
                        icon: "photo.on.rectangle.angled",
                        title: shouldSelectPrompt ? IconLocalization.string("select-category-prompt") : IconLocalization.string("no-icons-in-source")
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: gridItems, spacing: 16) {
                            ForEach(iconAssets) { iconAsset in
                                IconTilePreview(iconAsset)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .onAppear {
                updateGridItems(geo)
            }
            .onChange(of: geo.size.width) {
                updateGridItems(geo)
            }
        }
        .onAppear {
            loadIconAssets()
        }
        .onChange(of: selectedCategory) {
            loadIconAssets()
        }
        .onChange(of: selectedSourceIdentifier) {
            loadIconAssets()
        }
    }

    /// 更新网格列数
    private func updateGridItems(_ geo: GeometryProxy) {
        let availableWidth = geo.size.width - 32 // 减去左右padding
        let itemWidth: CGFloat = 60 // 每个图标项的宽度
        let spacing: CGFloat = 16 // 列间距
        let columns = max(Int((availableWidth + spacing) / (itemWidth + spacing)), 1)
        gridItems = Array(repeating: .init(.flexible()), count: columns)
    }

    /// 加载图标资源
    private func loadIconAssets() {
        isLoading = true

        Task {
            let assets: [IconAsset]
            if let sid = selectedSourceIdentifier,
               let source = IconRepo.shared.getAllIconSources().first(where: { $0.sourceIdentifier == sid }) {
                if source.supportsCategories,
                   let category = selectedCategory,
                   category.sourceIdentifier == sid {
                    assets = await IconRepo.shared.getIcons(for: category.id, sourceIdentifier: category.sourceIdentifier)
                } else {
                    assets = await IconRepo.shared.getAllIcons(for: sid)
                }
            } else {
                assets = []
            }
            await MainActor.run {
                self.iconAssets = assets
                self.isLoading = false
            }
        }
    }

    /// 通过文件选择器添加图片
    private func addImagesViaPanel() {
        let sid = selectedCategory?.sourceIdentifier ?? selectedSourceIdentifier
        guard let sid,
              IconRepo.shared.getAllIconSources().first(where: { $0.sourceIdentifier == sid })?.supportsMutations == true else { return }
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.png, .jpeg, .gif, .webP, .svg]
        panel.begin { response in
            guard response == .OK else { return }
            let urls = panel.urls
            Task.detached(priority: .userInitiated) {
                var okCount = 0
                for url in urls {
                    if let data = try? Data(contentsOf: url) {
                        if await IconRepo.shared.addImage(data: data, filename: url.lastPathComponent, to: sid) {
                            okCount += 1
                        }
                    }
                }
                await MainActor.run {
                    print("[IconGrid] addImagesViaPanel done: \(okCount)/\(urls.count)")
                    loadIconAssets()
                }
            }
        }
    }

    /// 通过文件选择器删除图片
    private func deleteImagesViaPanel() {
        guard let sid = selectedCategory?.sourceIdentifier,
              IconRepo.shared.getAllIconSources().first(where: { $0.sourceIdentifier == sid })?.supportsMutations == true else { return }
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.png, .jpeg, .gif, .webP, .svg]
        panel.begin { response in
            guard response == .OK else { return }
            let urls = panel.urls
            Task.detached(priority: .userInitiated) {
                var okCount = 0
                for url in urls {
                    if await IconRepo.shared.deleteImage(filename: url.lastPathComponent, from: sid) {
                        okCount += 1
                    }
                }
                await MainActor.run {
                    print("[IconGrid] deleteImagesViaPanel done: \(okCount)/\(urls.count)")
                    loadIconAssets()
                }
            }
        }
    }

    /// 当前来源下是否可删除所选图标
    private func canDeleteSelected(in sourceIdentifier: String) -> Bool {
        guard let source = IconRepo.shared.getAllIconSources().first(where: { $0.sourceIdentifier == sourceIdentifier }),
              source.supportsMutations else { return false }
        // 匹配所选图标是否属于当前网格集合
        let selectedId = iconProvider.selectedIconId
        if selectedId.isEmpty { return false }
        return iconAssets.contains { asset in
            // 本地：iconId 为去扩展名的文件名
            if asset.iconId == selectedId { return true }
            if let name = asset.fileURL?.lastPathComponent, name == selectedId || name.hasPrefix(selectedId + ".") { return true }
            return false
        }
    }

    /// 删除当前选择的图标（用于不支持分类的来源）
    private func deleteSelectedImage() {
        let selectedId = iconProvider.selectedIconId
        guard let sid = selectedSourceIdentifier,
              IconRepo.shared.getAllIconSources().first(where: { $0.sourceIdentifier == sid })?.supportsMutations == true,
              !selectedId.isEmpty else { return }

        // 定位所选资源，取文件名（带扩展名）
        guard let target = iconAssets.first(where: { asset in
            if asset.iconId == selectedId { return true }
            if let name = asset.fileURL?.lastPathComponent, name == selectedId || name.hasPrefix(selectedId + ".") { return true }
            return false
        }), let filename = target.fileURL?.lastPathComponent else { return }

        Task.detached(priority: .userInitiated) {
            let ok = await IconRepo.shared.deleteImage(filename: filename, from: sid)
            await MainActor.run {
                if ok {
                    if iconProvider.selectedIconId == selectedId {
                        iconProvider.selectedIconId = ""
                    }
                    loadIconAssets()
                }
            }
        }
    }
}
