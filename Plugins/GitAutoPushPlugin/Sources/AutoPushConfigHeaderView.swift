import AppKit
import GitOKCoreKit
import GitOKUI
import SwiftUI

/// 自动推送配置视图的标题栏
struct AutoPushConfigHeaderView: View {
    let isLoading: Bool
    let onClose: () -> Void

    var body: some View {
        HStack {
            headerTitle
            Spacer()
            headerActions
        }
        .padding()
        .gitOKUISurface(style: .toolbar, cornerRadius: 0)
        .overlay(separatorLine, alignment: .bottom)
    }

    // MARK: - Subviews

    private var headerTitle: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.up.circle")
                .foregroundColor(.blue)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(GitAutoPushPluginLocalization.string("Auto Push Configuration"))
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(GitAutoPushPluginLocalization.string("Manage auto-push settings for project branches."))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var headerActions: some View {
        HStack(spacing: 12) {
            if isLoading {
                AppLoadingOverlay(size: .small)
                    .frame(width: 28, height: 28)
            }

            AppButton(
                GitAutoPushPluginLocalization.string("Close"),
                style: .secondary,
                size: .small
            ) {
                onClose()
            }
            .keyboardShortcut(.cancelAction)
        }
    }

    private var separatorLine: some View {
        Rectangle()
            .frame(height: 1)
            .foregroundColor(Color(NSColor.separatorColor))
    }
}

#Preview("AutoPushConfigHeaderView") {
    AutoPushConfigHeaderView(
        isLoading: false,
        onClose: {}
    )
    .frame(width: 500)
}
