import SwiftUI

public enum CommitHistoryListMetrics {
    public static let loadingMoreIndicatorHeight: CGFloat = 44
}

public struct CommitHistoryListView<RowContent: View>: View {
    private let isLoading: Bool
    private let hasRows: Bool
    @Binding private var showsCommitGraph: Bool
    private let rowContent: () -> RowContent

    public init(
        isLoading: Bool,
        hasRows: Bool,
        showsCommitGraph: Binding<Bool>,
        @ViewBuilder rowContent: @escaping () -> RowContent
    ) {
        self.isLoading = isLoading
        self.hasRows = hasRows
        self._showsCommitGraph = showsCommitGraph
        self.rowContent = rowContent
    }

    public var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: []) {
                Divider()

                rowContent()

                if isLoading && hasRows {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .frame(height: CommitHistoryListMetrics.loadingMoreIndicatorHeight)

                    Divider()
                }
            }
        }
        .background(Color(.controlBackgroundColor))
        .contextMenu {
            Toggle(isOn: $showsCommitGraph) {
                Label("显示提交图", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
            }
        }
    }
}
