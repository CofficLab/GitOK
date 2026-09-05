import AppKit
import LumiUI
import SwiftUI

/// 阻断式工作区同步错误面板。
///
/// 面板挂在 RootView Overlay 上，而不是 Rail 内部，因此不会被 Rail 的
/// 尺寸或裁剪区域截断。错误详情使用滚动容器完整保留，并允许复制。
struct WorktreeSyncFailureOverlay<Content: View>: View {
    private let content: Content
    @ObservedObject private var center: WorktreeSyncFailureCenter
    @LumiTheme private var theme

    init(content: Content, center: WorktreeSyncFailureCenter) {
        self.content = content
        self.center = center
    }

    var body: some View {
        content
            .overlay {
                if let failure = center.failure {
                    ZStack {
                        Color.black.opacity(0.22)
                            .ignoresSafeArea()

                        failurePanel(failure)
                            .transition(.scale(scale: 0.96).combined(with: .opacity))
                    }
                    .zIndex(1)
                    .animation(.easeOut(duration: 0.18), value: failure.id)
                }
            }
    }

    private func failurePanel(_ failure: WorktreeSyncFailure) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "xmark.octagon.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.red)

                VStack(alignment: .leading, spacing: 4) {
                    Text(loc("Sync failed"))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(theme.textPrimary)
                    Text(failure.operation)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(theme.textSecondary)
                }

                Spacer(minLength: 12)
            }

            Divider()
                .padding(.vertical, 16)

            Text(loc("Git error details"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.textSecondary)
                .padding(.bottom, 6)

            ScrollView {
                Text(failure.message)
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
                    copyToClipboard(failure.message)
                } label: {
                    Label(loc("Copy error"), systemImage: "doc.on.doc")
                }
                .buttonStyle(.borderless)

                Spacer()

                Button(loc("Close")) {
                    center.dismiss()
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
    WorktreeStatusLocalization.string(key, bundle: .module)
}
