import Foundation
import SwiftUI

public struct CommitHistoryRowsView<Item, RowContent: View>: View {
    private let items: [Item]
    private let firstItemID: String?
    private let showsCommitGraph: Bool
    private let rowsByCommitID: [String: CommitGraphPresentationRules.Row]
    private let graphLaneCount: Int
    private let hasMoreItems: Bool
    private let isLoading: Bool
    @Binding private var isLoadingMoreScheduled: Bool
    private let id: (Item) -> String
    private let rowContent: (Item, Bool, Int, CommitGraphPresentationRules.Row?, Int) -> RowContent
    private let logScheduled: (Int) -> Void
    private let schedule: (TimeInterval, @escaping () -> Void) -> Void
    private let logExecuting: () -> Void
    private let loadMore: () -> Void

    private struct IndexedItem: Identifiable {
        let index: Int
        let item: Item
        let id: String
    }

    public init(
        items: [Item],
        firstItemID: String?,
        showsCommitGraph: Bool,
        rowsByCommitID: [String: CommitGraphPresentationRules.Row],
        graphLaneCount: Int,
        hasMoreItems: Bool,
        isLoading: Bool,
        isLoadingMoreScheduled: Binding<Bool>,
        id: @escaping (Item) -> String,
        @ViewBuilder rowContent: @escaping (Item, Bool, Int, CommitGraphPresentationRules.Row?, Int) -> RowContent,
        logScheduled: @escaping (Int) -> Void = { _ in },
        schedule: @escaping (TimeInterval, @escaping () -> Void) -> Void,
        logExecuting: @escaping () -> Void = {},
        loadMore: @escaping () -> Void
    ) {
        self.items = items
        self.firstItemID = firstItemID
        self.showsCommitGraph = showsCommitGraph
        self.rowsByCommitID = rowsByCommitID
        self.graphLaneCount = graphLaneCount
        self.hasMoreItems = hasMoreItems
        self.isLoading = isLoading
        _isLoadingMoreScheduled = isLoadingMoreScheduled
        self.id = id
        self.rowContent = rowContent
        self.logScheduled = logScheduled
        self.schedule = schedule
        self.logExecuting = logExecuting
        self.loadMore = loadMore
    }

    public var body: some View {
        ForEach(indexedItems) { indexedItem in
            rowContent(
                indexedItem.item,
                indexedItem.id == firstItemID,
                indexedItem.index,
                CommitGraphPresentationRules.row(
                    for: indexedItem.id,
                    showsCommitGraph: showsCommitGraph,
                    rowsByCommitID: rowsByCommitID
                ),
                graphLaneCount
            )
            .onAppear {
                let scheduleState = CommitListPaginationRules.loadMoreScheduleState(
                    appearedIndex: indexedItem.index,
                    totalCount: items.count,
                    hasMoreCommits: hasMoreItems,
                    isLoading: isLoading,
                    isAlreadyScheduled: isLoadingMoreScheduled
                )

                CommitListPaginationRules.performLoadMoreScheduleState(
                    scheduleState,
                    setScheduled: { isLoadingMoreScheduled = $0 },
                    logScheduled: {
                        logScheduled(indexedItem.index)
                    },
                    schedule: schedule,
                    logExecuting: logExecuting,
                    loadMore: loadMore
                )
            }
        }
    }

    private var indexedItems: [IndexedItem] {
        Array(items.enumerated()).map { index, item in
            IndexedItem(index: index, item: item, id: id(item))
        }
    }
}
