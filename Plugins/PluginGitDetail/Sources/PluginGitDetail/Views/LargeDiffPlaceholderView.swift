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

            Text(String(localized: "Diff is too large, rendering skipped"))
                .font(.headline)

            Text(String(localized: "The current diff is approximately \(characterCount.formatted()) characters. To avoid UI lag, GitOK does not render oversized patches directly; you can still copy the raw diff or view the file text."))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            HStack(spacing: 10) {
                Button(String(localized: "Copy Raw Diff"), action: onCopyRawDiff)

                if canShowBeforeText {
                    Button(String(localized: "View Original Text"), action: onShowBeforeText)
                }

                if canShowAfterText {
                    Button(String(localized: "View New Text"), action: onShowAfterText)
                }
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}
