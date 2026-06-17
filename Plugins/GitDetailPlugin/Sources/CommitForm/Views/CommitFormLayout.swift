import GitOKCoreKit
import ProjectSupportKit
import SwiftUI

public struct CommitFormLayout<UserContent: View>: View {
    @Binding private var text: String
    @Binding private var category: CommitCategory
    @Binding private var selectedCoAuthors: [CoAuthor]
    @Binding private var commitStyle: CommitStyle

    private let issueReferences: [String]
    private let userMentions: [String]
    private let commitOnlyTitle: String
    private let commitAndPushTitle: String
    private let onCommitStyleSelectionChange: (CommitStyle) -> Void
    private let onCommitOnly: () -> Void
    private let onCommitAndPush: () -> Void
    private let userContent: () -> UserContent

    public init(
        text: Binding<String>,
        category: Binding<CommitCategory>,
        selectedCoAuthors: Binding<[CoAuthor]>,
        commitStyle: Binding<CommitStyle>,
        issueReferences: [String],
        userMentions: [String],
        commitOnlyTitle: String = "提交",
        commitAndPushTitle: String = "提交并推送",
        onCommitStyleSelectionChange: @escaping (CommitStyle) -> Void,
        onCommitOnly: @escaping () -> Void,
        onCommitAndPush: @escaping () -> Void,
        @ViewBuilder userContent: @escaping () -> UserContent
    ) {
        self._text = text
        self._category = category
        self._selectedCoAuthors = selectedCoAuthors
        self._commitStyle = commitStyle
        self.issueReferences = issueReferences
        self.userMentions = userMentions
        self.commitOnlyTitle = commitOnlyTitle
        self.commitAndPushTitle = commitAndPushTitle
        self.onCommitStyleSelectionChange = onCommitStyleSelectionChange
        self.onCommitOnly = onCommitOnly
        self.onCommitAndPush = onCommitAndPush
        self.userContent = userContent
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                HStack(spacing: 0) {
                    CommitStylePicker(
                        selection: $commitStyle,
                        onSelectionChange: onCommitStyleSelectionChange
                    )

                    CommitCategoryPicker(
                        selection: $category,
                        commitStyle: commitStyle
                    )
                }

                Spacer()
                CommitMessageInput(
                    text: $text,
                    issueReferences: issueReferences,
                    userMentions: userMentions
                )
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    userContent()
                        .frame(maxWidth: 100)
                }

                Spacer()

                CommitSubmitButton(commitOnlyTitle, action: onCommitOnly)

                CommitSubmitButton(commitAndPushTitle, action: onCommitAndPush)
            }
            .frame(height: 50)
        }
    }
}
