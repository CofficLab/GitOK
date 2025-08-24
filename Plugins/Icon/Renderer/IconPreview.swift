import MagicCore
import SwiftUI

/**
 * 图标预览组件
 * 显示单个图标预览，自动适应当前可用空间
 * 使用IconRenderer来渲染图标样式
 * 自动从IconProvider环境变量中获取图标数据
 */
struct IconPreview: View {
    let iconData: IconData
    
    @EnvironmentObject var iconProvider: IconProvider
    @State private var iconAsset: IconAsset?
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 16) {
            Text("图标预览")
                .font(.title2)
                .fontWeight(.semibold)
            
            // 自适应图标预览
            GeometryReader { geometry in
                let availableSize = min(geometry.size.width, geometry.size.height) * 0.8
                
                if let iconAsset = iconAsset, !isLoading && errorMessage == nil {
                    IconRenderer.renderIcon(iconData: iconData, iconAsset: iconAsset)
                        .frame(width: availableSize, height: availableSize)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if isLoading {
                    // 显示加载状态
                    VStack(spacing: 12) {
                        ProgressView()
                            .frame(width: 50, height: 50)
                        Text("加载图标中...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(width: availableSize, height: availableSize)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = errorMessage {
                    // 显示错误状态
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text("加载失败")
                            .font(.headline)
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("重试") {
                            loadIconAsset()
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(width: availableSize, height: availableSize)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // 显示空状态
                    VStack(spacing: 12) {
                        Image(systemName: "photo")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("请选择一个图标")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(width: availableSize, height: availableSize)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .onAppear {
            loadIconAsset()
        }
        .onChange(of: iconProvider.selectedIconId) { _, newValue in
            // 当selectedIconId变化时，立即清空当前图标并重新加载
            if !newValue.isEmpty {
                self.iconAsset = nil
                self.errorMessage = nil
                self.isLoading = true
                loadIconAsset()
            } else {
                // 如果没有选中的图标，清空所有状态
                self.iconAsset = nil
                self.errorMessage = nil
                self.isLoading = false
            }
        }
    }
    
    private func loadIconAsset() {
        guard !iconProvider.selectedIconId.isEmpty else {
            self.iconAsset = nil
            self.errorMessage = nil
            self.isLoading = false
            return
        }
        
        // 设置超时，避免无限loading
        Task {
            do {
                // 添加超时处理
                let iconAsset = try await withTimeout(seconds: 10) {
                    await IconRepo.shared.getIconAsset(byId: iconProvider.selectedIconId)
                }
                
                await MainActor.run {
                    if let iconAsset = iconAsset {
                        self.iconAsset = iconAsset
                        self.errorMessage = nil
                        self.isLoading = false
                    } else {
                        self.iconAsset = nil
                        self.errorMessage = "未找到图标：\(iconProvider.selectedIconId)"
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.iconAsset = nil
                    self.errorMessage = "加载失败：\(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - 超时扩展

extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: TimeInterval) async {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}

func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        
        group.addTask {
            try await Task.sleep(seconds: seconds)
            throw TimeoutError()
        }
        
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}

struct TimeoutError: Error, LocalizedError {
    var errorDescription: String? {
        return "操作超时"
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
