
import SwiftUI

/**
 * 图标下载按钮组件
 * 提供多种格式的图标下载功能
 * 支持PNG、Favicon、Xcode等格式
 */
struct DownloadButtons: View {
    @EnvironmentObject var iconProvider: IconProvider
    @State private var currentIconAsset: IconAsset?

    var body: some View {
        VStack(spacing: 8) {
            XcodeDownloadButton(iconProvider: iconProvider, currentIconAsset: currentIconAsset)
            PNGDownloadButton(iconProvider: iconProvider, currentIconAsset: currentIconAsset)
            FaviconDownloadButton(iconProvider: iconProvider, currentIconAsset: currentIconAsset)
            ImageSetDownloadButton(iconProvider: iconProvider, currentIconAsset: currentIconAsset)

            if currentIconAsset == nil || iconProvider.currentData == nil {
                Text("请先选择一个图标")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            loadCurrentIconAsset()
        }
        .onChange(of: iconProvider.selectedIconId) { _, _ in
            loadCurrentIconAsset()
        }
        .onChange(of: iconProvider.currentData) { _, _ in
            loadCurrentIconAsset()
        }
    }

    // MARK: - 私有方法

    private func loadCurrentIconAsset() {
        guard !iconProvider.selectedIconId.isEmpty else {
            currentIconAsset = nil
            return
        }

        Task {
            do {
                if let iconAsset = try await IconRepo.shared.getIconAsset(byId: iconProvider.selectedIconId) {
                    await MainActor.run {
                        self.currentIconAsset = iconAsset
                    }
                } else {
                    await MainActor.run {
                        self.currentIconAsset = nil
                    }
                }
            } catch {
                await MainActor.run {
                    self.currentIconAsset = nil
                }
                // 可以在这里添加错误日志或用户提示
                print("加载图标失败：\(error.localizedDescription)")
            }
        }
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
    .frame(height: 800)
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
