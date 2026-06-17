import SwiftUI

public struct GitDetailHeaderContentView<CommitInfoContent: View, CommitFormContent: View>: View {
    private let mode: GitDetailPresentationRules.HeaderContentMode
    private let commitInfoContent: () -> CommitInfoContent
    private let commitFormContent: () -> CommitFormContent

    public init(
        mode: GitDetailPresentationRules.HeaderContentMode,
        @ViewBuilder commitInfoContent: @escaping () -> CommitInfoContent,
        @ViewBuilder commitFormContent: @escaping () -> CommitFormContent
    ) {
        self.mode = mode
        self.commitInfoContent = commitInfoContent
        self.commitFormContent = commitFormContent
    }

    public var body: some View {
        switch mode {
        case .none:
            EmptyView()
        case .commitInfo:
            commitInfoContent()
        case .commitForm:
            commitFormContent()
        }
    }
}
