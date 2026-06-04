
import SwiftUI
import GitOKCoreKit
import UniformTypeIdentifiers

/**
 * 图标制作器主视图
 * 负责显示图标预览和多种格式的下载功能
 * 采用水平布局：左侧显示图标预览，右侧提供下载选项
 */
struct IconMaker: View {
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
                        self.errorMessage = IconLocalization.string("icon-not-found").replacingOccurrences(of: "%@", with: i.selectedIconId)
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.iconAsset = nil
                    self.errorMessage = IconLocalization.string("load-icon-failed").replacingOccurrences(of: "%@", with: error.localizedDescription)
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
        AppLoadingOverlay(message: IconLocalization.string("loading-icons"), size: .large)
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

            Text(IconLocalization.string("loading-failed"))
                .font(.headline)
                .foregroundColor(.primary)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            AppButton(
                IconLocalization.string("retry"),
                systemImage: "arrow.clockwise",
                style: .primary
            ) {
                onRetry()
            }
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

            Text(IconLocalization.string("icon-workshop"))
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text(IconLocalization.string("select-icon-to-start"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // 制作功能提示
            HStack(spacing: 20) {
                FeatureHint(icon: "pencil.and.outline", title: IconLocalization.string("edit"), description: IconLocalization.string("adjust-colors-style"))
                FeatureHint(icon: "square.and.arrow.down", title: IconLocalization.string("export"), description: IconLocalization.string("multiple-formats"))
                FeatureHint(icon: "doc.badge.plus", title: IconLocalization.string("draft"), description: IconLocalization.string("save-progress"))
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
