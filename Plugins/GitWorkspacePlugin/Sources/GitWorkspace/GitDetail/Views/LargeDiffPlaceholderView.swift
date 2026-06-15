import GitOKUI
import SwiftUI

public struct LargeDiffPlaceholderView: View {
    private let characterCount: Int
    private let canShowBeforeText: Bool
    private let canShowAfterText: Bool
    private let onCopyRawDiff: () -> Void
    private let onShowBeforeText: () -> Void
    private let onShowAfterText: () -> Void

    public init(
        characterCount: Int,
        canShowBeforeText: Bool,
        canShowAfterText: Bool,
        onCopyRawDiff: @escaping () -> Void,
        onShowBeforeText: @escaping () -> Void,
        onShowAfterText: @escaping () -> Void
    ) {
        self.characterCount = characterCount
        self.canShowBeforeText = canShowBeforeText
        self.canShowAfterText = canShowAfterText
        self.onCopyRawDiff = onCopyRawDiff
        self.onShowBeforeText = onShowBeforeText
        self.onShowAfterText = onShowAfterText
    }

    public var body: some View {
        VStack(spacing: 14) {
            Spacer()

            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 36))
                .foregroundColor(.orange)

            Text(GitDetailLocalization.string("Diff is too large, rendering skipped"))
                .font(.headline)

            Text(GitDetailLocalization.string("The current diff is approximately \(characterCount.formatted()) characters. To avoid UI lag, GitOK does not render oversized patches directly; you can still copy the raw diff or view the file text."))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            HStack(spacing: 10) {
                AppButton(
                    GitDetailLocalization.string("Copy Raw Diff"),
                    systemImage: "doc.on.doc",
                    style: .secondary,
                    size: .small,
                    action: onCopyRawDiff
                )

                if canShowBeforeText {
                    AppButton(
                        GitDetailLocalization.string("View Original Text"),
                        systemImage: "doc.text",
                        style: .secondary,
                        size: .small,
                        action: onShowBeforeText
                    )
                }

                if canShowAfterText {
                    AppButton(
                        GitDetailLocalization.string("View New Text"),
                        systemImage: "doc.text.fill",
                        style: .secondary,
                        size: .small,
                        action: onShowAfterText
                    )
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}
