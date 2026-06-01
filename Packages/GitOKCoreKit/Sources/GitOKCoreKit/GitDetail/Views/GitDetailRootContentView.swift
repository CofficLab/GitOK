import SwiftUI

public struct GitDetailRootContentView<
    HeaderContent: View,
    FileListContent: View,
    FileDetailContent: View,
    EmptyContent: View,
    NotGitContent: View
>: View {
    private let presentationState: GitDetailPresentationRules.PresentationState
    private let headerContent: () -> HeaderContent
    private let fileListContent: () -> FileListContent
    private let fileDetailContent: () -> FileDetailContent
    private let emptyContent: () -> EmptyContent
    private let notGitContent: () -> NotGitContent

    public init(
        presentationState: GitDetailPresentationRules.PresentationState,
        @ViewBuilder headerContent: @escaping () -> HeaderContent,
        @ViewBuilder fileListContent: @escaping () -> FileListContent,
        @ViewBuilder fileDetailContent: @escaping () -> FileDetailContent,
        @ViewBuilder emptyContent: @escaping () -> EmptyContent,
        @ViewBuilder notGitContent: @escaping () -> NotGitContent
    ) {
        self.presentationState = presentationState
        self.headerContent = headerContent
        self.fileListContent = fileListContent
        self.fileDetailContent = fileDetailContent
        self.emptyContent = emptyContent
        self.notGitContent = notGitContent
    }

    public var body: some View {
        switch presentationState.rootContentMode {
        case .hidden:
            EmptyView()
        case .gitProject:
            GitDetailContentLayout(
                showsHeader: presentationState.contentVisibility.showsHeader,
                showsFileSplit: presentationState.contentVisibility.showsFileSplit,
                headerContent: headerContent,
                fileListContent: fileListContent,
                fileDetailContent: fileDetailContent,
                emptyContent: emptyContent
            )
        case .notGitProject:
            notGitContent()
        }
    }
}
