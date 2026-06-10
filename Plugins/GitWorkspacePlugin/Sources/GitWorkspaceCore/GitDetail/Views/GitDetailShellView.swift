import SwiftUI

public struct GitDetailShellView<CommitInfoContent: View, FileListContent: View, FileDetailContent: View, EmptyContent: View, NotGitContent: View, CommitFormContent: View>: View {
    private let presentationState: GitDetailPresentationRules.PresentationState
    private let commitInfoContent: () -> CommitInfoContent
    private let fileListContent: () -> FileListContent
    private let fileDetailContent: () -> FileDetailContent
    private let emptyContent: () -> EmptyContent
    private let notGitContent: () -> NotGitContent
    private let commitFormContent: () -> CommitFormContent

    public init(
        presentationState: GitDetailPresentationRules.PresentationState,
        @ViewBuilder commitInfoContent: @escaping () -> CommitInfoContent,
        @ViewBuilder fileListContent: @escaping () -> FileListContent,
        @ViewBuilder fileDetailContent: @escaping () -> FileDetailContent,
        @ViewBuilder emptyContent: @escaping () -> EmptyContent,
        @ViewBuilder notGitContent: @escaping () -> NotGitContent,
        @ViewBuilder commitFormContent: @escaping () -> CommitFormContent
    ) {
        self.presentationState = presentationState
        self.commitInfoContent = commitInfoContent
        self.fileListContent = fileListContent
        self.fileDetailContent = fileDetailContent
        self.emptyContent = emptyContent
        self.notGitContent = notGitContent
        self.commitFormContent = commitFormContent
    }

    public var body: some View {
        GitDetailRootContentView(
            presentationState: presentationState,
            headerContent: {
                GitDetailHeaderContentView(mode: presentationState.headerContentMode) {
                    commitInfoContent()
                } commitFormContent: {
                    commitFormContent()
                }
            },
            fileListContent: fileListContent,
            fileDetailContent: fileDetailContent,
            emptyContent: emptyContent,
            notGitContent: notGitContent
        )
    }
}
