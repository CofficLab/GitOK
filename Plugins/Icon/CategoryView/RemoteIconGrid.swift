import MagicCore
import SwiftUI

/**
 * 远程图标网格组件
 * 负责展示远程图标，支持异步加载和错误处理
 * 数据流：IconRepo -> RemoteIcon List
 */
struct RemoteIconGrid: View {
    let gridItems: [GridItem]

    @State private var remoteIcons: [RemoteIcon] = []
    @State private var isLoading: Bool = true
    @State private var hasError: Bool = false
    @EnvironmentObject var iconProvider: IconProvider

    /// 当前选中的分类ID
    private var selectedCategoryId: String {
        iconProvider.selectedRemoteCategoryId.isEmpty ? "basic" : iconProvider.selectedRemoteCategoryId
    }

    var body: some View {
        VStack(spacing: 16) {
            if isLoading {
                // 加载状态
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("正在加载远程图标...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if hasError {
                // 错误状态
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    Text("加载远程图标失败")
                        .font(.headline)
                        .foregroundColor(.red)
                    Button("重试") {
                        loadRemoteIcons()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // 正常显示图标网格
                LazyVGrid(columns: gridItems, spacing: 12) {
                    ForEach(remoteIcons, id: \.id) { remoteIcon in
                        IconView(iconAsset: IconAsset(remotePath: remoteIcon.path))
                    }
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            loadRemoteIcons()
        }
        .onChange(of: selectedCategoryId) {
            loadRemoteIcons()
        }
    }

    /// 加载远程图标
    private func loadRemoteIcons() {
        isLoading = true
        hasError = false

        Task {
            do {
                let allCategories = await IconRepo.shared.getAllCategories()
                if let remoteCategory = allCategories.first(where: { $0.source == .remote && $0.remoteCategory?.id == selectedCategoryId }) {
                    let iconAssets = await IconRepo.shared.getIcons(for: remoteCategory)
                    // 将 IconAsset 转换为 RemoteIcon 以保持兼容性
                    let remoteIcons = iconAssets.compactMap { iconAsset -> RemoteIcon? in
                        guard iconAsset.source == .remote,
                              let remotePath = iconAsset.remotePath else { return nil }
                        
                        return RemoteIcon(
                            id: iconAsset.id,
                            name: iconAsset.iconId,
                            path: remotePath,
                            category: iconAsset.categoryName,
                            fullPath: remotePath,
                            size: 0,
                            modified: ""
                        )
                    }
                    await MainActor.run {
                        self.remoteIcons = remoteIcons
                        isLoading = false
                    }
                } else {
                    await MainActor.run {
                        remoteIcons = []
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    hasError = true
                    isLoading = false
                }
            }
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .setInitialTab("Icon")
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .setInitialTab("Icon")
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
