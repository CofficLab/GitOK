import AppKit
import LumiUI
import SwiftUI

/// 根视图级提交错误面板，确保错误不会随提交表单隐藏而丢失。
@MainActor
struct CommitFormErrorOverlay<Content: View>: View {
    private let content: Content
    @ObservedObject private var center: CommitFormErrorCenter
    @LumiTheme private var theme

    init(content: Content, center: CommitFormErrorCenter) {
        self.content = content
        self.center = center
    }

    var body: some View {
        content
            .overlay {
                if let error = center.error {
                    ZStack {
                        Color.black.opacity(0.22)
                            .ignoresSafeArea()

                        panel(error)
                            .transition(.scale(scale: 0.96).combined(with: .opacity))
                    }
                    .zIndex(1)
                    .animation(.easeOut(duration: 0.18), value: error.id)
                }
            }
    }

    private func panel(_ error: CommitFormError) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(loc("Commit operation failed"))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(theme.textPrimary)
                    Text(error.operation)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(theme.textSecondary)
                }

                Spacer(minLength: 12)

                Image(systemName: "xmark.octagon.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.red)
            }

            Divider()
                .padding(.vertical, 16)

            Text(loc("Git error details"))
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
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(error.message, forType: .string)
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

    private func loc(_ key: String) -> String {
        CommitFormLocalization.string(key, bundle: .module)
    }
}
