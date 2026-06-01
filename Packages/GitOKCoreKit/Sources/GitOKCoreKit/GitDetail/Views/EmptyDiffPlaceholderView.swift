import SwiftUI

public struct EmptyDiffPlaceholderView: View {
    private let changeType: String
    private let issueMessage: String?
    private let canShowBeforeText: Bool
    private let canShowAfterText: Bool
    private let onRefresh: () -> Void
    private let onShowBeforeText: () -> Void
    private let onShowAfterText: () -> Void
    private let onCopyReason: () -> Void

    public init(
        changeType: String,
        issueMessage: String?,
        canShowBeforeText: Bool,
        canShowAfterText: Bool,
        onRefresh: @escaping () -> Void,
        onShowBeforeText: @escaping () -> Void,
        onShowAfterText: @escaping () -> Void,
        onCopyReason: @escaping () -> Void
    ) {
        self.changeType = changeType
        self.issueMessage = issueMessage
        self.canShowBeforeText = canShowBeforeText
        self.canShowAfterText = canShowAfterText
        self.onRefresh = onRefresh
        self.onShowBeforeText = onShowBeforeText
        self.onShowAfterText = onShowAfterText
        self.onCopyReason = onCopyReason
    }

    public var body: some View {
        VStack(spacing: 14) {
            Spacer()

            Image(systemName: issueMessage == nil ? "doc.text.magnifyingglass" : "exclamationmark.triangle")
                .font(.system(size: 34))
                .foregroundColor(issueMessage == nil ? .secondary : .orange)

            Text(issueMessage == nil ? String(localized: "No differences to display") : String(localized: "Unable to display differences"))
                .font(.headline)
                .foregroundColor(.primary)

            Text(GitDetailDiffDisplayRules.emptyDiffExplanation(
                changeType: changeType,
                issueMessage: issueMessage
            ))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            if let issueMessage, issueMessage.isEmpty == false {
                Text(String(localized: "Reason: \(issueMessage)"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Text(String(localized: "File Status: \(GitDetailDiffDisplayRules.changeTypeLabel(changeType))"))
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 10) {
                Button(String(localized: "Refresh"), action: onRefresh)

                if canShowBeforeText {
                    Button(String(localized: "View Original Text"), action: onShowBeforeText)
                }

                if canShowAfterText {
                    Button(String(localized: "View New Text"), action: onShowAfterText)
                }

                if let issueMessage, issueMessage.isEmpty == false {
                    Button(String(localized: "Copy Reason"), action: onCopyReason)
                }
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}
