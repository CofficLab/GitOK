import AppKit
import LumiUI
import ProviderToast
import SwiftUI

// MARK: - Toast Overlay

/// 挂在主窗口根部的 Toast 渲染覆盖层。
///
/// 订阅共享的 `ToastCenter`（即 `ToastProviding` 实现），在窗口顶部
/// 渲染当前 toast。Toast 本身不参与交互（`allowsHitTesting(false)`），
/// 不遮挡下方内容。
public struct ToastOverlay<Content: View>: View {
    private let content: Content
    @ObservedObject private var center: ToastCenter

    public init(content: Content, center: ToastCenter) {
        self.content = content
        self.center = center
    }

    public var body: some View {
        content
            .overlay(alignment: .top) {
                Group {
                    if let toast = center.currentToast {
                        ToastView(toast: toast)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .animation(.spring(duration: 0.3), value: center.currentToast)
                .allowsHitTesting(false)
            }
            .overlay {
                if let error = center.currentError {
                    ErrorNoticeOverlay(error: error, center: center)
                        .transition(.scale(scale: 0.96).combined(with: .opacity))
                }
            }
    }
}

// MARK: - Persistent Error Notice

/// 持久化错误面板：保留完整信息，支持滚动、文本选择、复制与用户确认关闭。
private struct ErrorNoticeOverlay: View {
    private let error: LumiErrorNotice
    @ObservedObject private var center: ToastCenter
    @LumiTheme private var theme

    init(error: LumiErrorNotice, center: ToastCenter) {
        self.error = error
        self.center = center
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.22)
                .ignoresSafeArea()

            errorPanel
        }
        .zIndex(1)
        .animation(.easeOut(duration: 0.18), value: error.id)
    }

    private var errorPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "xmark.octagon.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.red)

                Text(error.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(theme.textPrimary)

                Spacer(minLength: 12)
            }

            Divider()
                .padding(.vertical, 16)

            Text(loc("Error details"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.textSecondary)
                .padding(.bottom, 6)

            ScrollView {
                Text(error.message)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(theme.textPrimary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
            }
            .frame(minHeight: 100, maxHeight: 280)
            .background(theme.surface.opacity(0.75), in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(theme.textSecondary.opacity(0.18), lineWidth: 1)
            }

            HStack {
                Button {
                    copyToClipboard(error.message)
                } label: {
                    Label(loc("Copy error"), systemImage: "doc.on.doc")
                }
                .buttonStyle(.borderless)

                Spacer()

                Button(loc("Close")) {
                    center.dismissError()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding(.top, 18)
        }
        .padding(24)
        .frame(minWidth: 480, idealWidth: 620, maxWidth: 720)
        .background(theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(theme.textSecondary.opacity(0.22), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.24), radius: 28, y: 12)
        .padding(28)
    }

    private func copyToClipboard(_ message: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(message, forType: .string)
    }
}

private func loc(_ key: String) -> String {
    LumiPluginLocalization.string(key, bundle: .module)
}

// MARK: - Toast View

/// 单条 Toast 的视觉样式：图标 + 标题 + 可选副标题，顶部浮动卡片。
struct ToastView: View {
    private let toast: LumiToast

    init(toast: LumiToast) {
        self.toast = toast
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: toast.style.systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(toast.style.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(toast.title)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                if let detail = toast.detail {
                    Text(detail)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .frame(maxWidth: 380)
        .background(
            .regularMaterial,
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(.quaternary, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
}

// MARK: - LumiToastStyle Extensions

extension LumiToastStyle {
    /// 对应的 SF Symbol 图标名。
    var systemImage: String {
        switch self {
        case .info: "info.circle"
        case .success: "checkmark.circle"
        case .warning: "exclamationmark.triangle"
        case .error: "xmark.octagon"
        }
    }

    /// 对应的强调色。
    var tint: Color {
        switch self {
        case .info: Color.accentColor
        case .success: .green
        case .warning: .orange
        case .error: .red
        }
    }
}
