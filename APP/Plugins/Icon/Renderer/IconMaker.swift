
import SwiftUI
import MagicAlert
import UniformTypeIdentifiers

/**
 * 图标制作器主视图
 * 负责显示图标预览和多种格式的下载功能
 * 采用水平布局：左侧显示图标预览，右侧提供下载选项
 */
struct IconMaker: View {
    @EnvironmentObject var app: AppVM
    
    @EnvironmentObject var i: IconProvider
    
    @State private var iconAsset: IconAsset?
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            if let iconData = i.currentData, let iconAsset = iconAsset {
                // 有图标数据时显示预览
                IconPreview(
                    iconData: iconData,
                    iconAsset: iconAsset,
                    applyBackground: true
                )
                .padding()
            } else if isLoading {
                // 加载状态
                LoadingStateView()
            } else if let errorMessage = errorMessage {
                // 错误状态
                ErrorStateView(
                    message: errorMessage,
                    onRetry: loadIconAsset
                )
            } else {
                // 空状态 - 没有选择图标
                EmptyStateView()
            }
        }
        .onAppear {
            loadIconAsset()
        }
        .onChange(of: i.selectedIconId) { _, newValue in
            if !newValue.isEmpty {
                self.iconAsset = nil
                self.errorMessage = nil
                self.isLoading = true
                loadIconAsset()
            } else {
                self.iconAsset = nil
                self.errorMessage = nil
                self.isLoading = false
            }
        }
        .onChange(of: i.currentData) { _, newValue in
            if newValue != nil {
                loadIconAsset()
            }
        }
    }
    
    private func loadIconAsset() {
        guard !i.selectedIconId.isEmpty else {
            self.iconAsset = nil
            self.errorMessage = nil
            self.isLoading = false
            return
        }

        Task {
            do {
                let iconAsset = try await IconRepo.shared.getIconAsset(byId: i.selectedIconId)

                await MainActor.run {
                    if let iconAsset = iconAsset {
                        self.iconAsset = iconAsset
                        self.errorMessage = nil
                        self.isLoading = false
                    } else {
                        self.iconAsset = nil
                        self.errorMessage = String(localized: "icon-not-found", table: "Icon").replacingOccurrences(of: "%@", with: i.selectedIconId)
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.iconAsset = nil
                    self.errorMessage = String(localized: "load-icon-failed", table: "Icon").replacingOccurrences(of: "%@", with: error.localizedDescription)
                    self.isLoading = false
                }
            }
        }
    }
}

/**
 * 加载状态视图
 * 显示图标加载中的状态
 */
struct LoadingStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .frame(width: 60, height: 60)
            
            Text(String(localized: "loading-icons", table: "Icon"))
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
}

/**
 * 错误状态视图
 * 显示图标加载失败的状态
 */
struct ErrorStateView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text(String(localized: "loading-failed", table: "Icon"))
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(String(localized: "retry", table: "Icon")) {
                onRetry()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.quaternary, lineWidth: 1)
        )
    }
}

/**
 * 空状态视图
 * 显示没有选择图标时的状态
 */
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            // 制作工具图标
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 80, height: 80)
                
                Image(systemName: "paintbrush.pointed")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(.linearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            }
            
            Text(String(localized: "icon-workshop", table: "Icon"))
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text(String(localized: "select-icon-to-start", table: "Icon"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // 制作功能提示
            HStack(spacing: 20) {
                FeatureHint(icon: "pencil.and.outline", title: String(localized: "edit", table: "Icon"), description: String(localized: "adjust-colors-style", table: "Icon"))
                FeatureHint(icon: "square.and.arrow.down", title: String(localized: "export", table: "Icon"), description: String(localized: "multiple-formats", table: "Icon"))
                FeatureHint(icon: "doc.badge.plus", title: String(localized: "draft", table: "Icon"), description: String(localized: "save-progress", table: "Icon"))
            }
            .padding(.top, 8)
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.quaternary, lineWidth: 1)
        )
    }
}

/**
 * 功能提示组件
 * 展示制作工具的主要功能
 */
struct FeatureHint: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text(description)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(width: 80)
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
    .frame(height: 800)
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
