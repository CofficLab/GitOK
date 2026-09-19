import LumiUI
import ProviderToast
import SwiftUI

// MARK: - Persistent Error Notice

/// 持久化错误面板：保留完整信息，支持滚动、文本选择、复制与用户确认关闭。
///
/// 面板骨架、阴影、复制按钮与操作按钮全部由 LumiUI 组件与设计令牌绘制
/// （`appSurface` / `appShadow` / `ErrorIconView` / `AppDivider` /
/// `AppSectionLabel` / `CopyMessageButton` / `AppButton`），本视图只负责排版
/// 与业务动作（关闭错误通知）。
struct ErrorNoticeOverlay: View {
    private let error: LumiErrorNotice
    @ObservedObject private var center: ToastCenter
    @LumiTheme private var theme
    @LumiMotionPreferenceReader private var motionPreference
    @State private var showCopyFeedback = false

    init(error: LumiErrorNotice, center: ToastCenter) {
        self.error = error
        self.center = center
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.22)
                .ignoresSafeArea()
                .transition(.opacity)

            panel
                .transition(.scale(scale: 0.96).combined(with: .opacity))
        }
        .zIndex(1)
        .animation(
            LumiMotion.enabled(LumiMotion.statusPresentation, preference: motionPreference),
            value: error.id
        )
    }
}

// MARK: - View

extension ErrorNoticeOverlay {
    private var panel: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            AppDivider()
                .padding(.vertical, DesignTokens.Spacing.md)

            AppSectionLabel(LumiPluginLocalization.string("Error details", bundle: .module))
                .padding(.bottom, DesignTokens.Spacing.xs)

            messageBox

            footer
        }
        .padding(DesignTokens.Spacing.lg)
        .frame(minWidth: 480, idealWidth: 620, maxWidth: 720)
        .appSurface(
            style: .panel,
            cornerRadius: DesignTokens.Radius.md,
            borderColor: theme.appSubtleBorder
        )
        .appShadow(.xxxl)
        .padding(DesignTokens.Spacing.lg)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
            ErrorIconView(size: 22, weight: .semibold)

            Text(error.title)
                .font(DesignTokens.Typography.title3)
                .foregroundStyle(theme.textPrimary)

            Spacer(minLength: DesignTokens.Spacing.sm)
        }
    }

    private var messageBox: some View {
        ScrollView {
            Text(error.message)
                .font(DesignTokens.Typography.code)
                .foregroundStyle(theme.textPrimary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(DesignTokens.Spacing.sm)
        }
        .frame(minHeight: 100, maxHeight: 280)
        .appSurface(
            style: .subtle,
            cornerRadius: DesignTokens.Radius.sm,
            borderColor: theme.appSubtleBorder
        )
    }

    private var footer: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            CopyMessageButton(content: error.message, showFeedback: $showCopyFeedback)

            Spacer()

            AppButton(
                LumiPluginLocalization.string("Close", bundle: .module),
                style: .primary
            ) {
                center.dismissError()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(.top, DesignTokens.Spacing.md)
    }
}

// MARK: - Preview

@MainActor
private struct ErrorNoticePreviewHost: View {
    private let center: ToastCenter

    init() {
        let center = ToastCenter()
        center.presentError(
            title: "Pull failed",
            message: "hint: You have divergent branches and need to specify how to reconcile them.\n"
                + "fatal: Need to specify how to reconcile divergent branches."
        )
        self.center = center
    }

    var body: some View {
        ErrorNoticeOverlay(error: center.currentError!, center: center)
    }
}

#Preview("App - Large") {
    ErrorNoticePreviewHost()
        .inRootView()
        .frame(width: 800, height: 600)
}

#Preview("App - Small") {
    ErrorNoticePreviewHost()
        .inRootView()
        .frame(width: 520, height: 480)
}
