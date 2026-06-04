import Dispatch
import SwiftUI

public enum CommitListHostLogEvent {
    case refresh(reason: String)
    case loadMoreFailure(Error)
    case duplicateLoadMore
}

public struct CommitListHostView<Project, Item, UnpushedItem, WorkingStateContent: View, RowContent: View>: View where Item: Sendable, UnpushedItem: Sendable {
    private let project: Project?
    private let projectPath: (Project) -> String
    private let loadItems: (Project, Int, Int) async throws -> [Item]
    private let loadUnpushedItems: (Project) async throws -> [UnpushedItem]
    private let itemID: (Item) -> String
    private let itemParentIDs: (Item) -> [String]
    private let unpushedID: (UnpushedItem) -> String
    private let updateUnpushed: (Int, [String]) -> Void
    private let selectItem: (Item?) -> Void
    private let loadLastSelectedID: (String) -> String?
    private let logEvent: (CommitListHostLogEvent) -> Void
    private let refreshToken: Int
    private let refreshReason: String
    private let workingStateContent: (Binding<Bool>) -> WorkingStateContent
    private let rowContent: (Item, Bool, Int, CommitGraphPresentationRules.Row?, Int) -> RowContent

    @State private var items: [Item] = []
    @State private var graphRowsByItemID: [String: CommitGraphPresentationRules.Row] = [:]
    @State private var graphLaneCount = 1
    @State private var loading = false
    @State private var hasMoreItems = true
    @State private var currentPage = 0
    @State private var pageSize = CommitListPaginationRules.defaultPageSize
    @State private var isLoadingMoreScheduled = false
    @State private var currentRefreshTask: Task<Void, Never>?

    @AppStorage(CommitListPaginationRules.showCommitGraphStorageKey)
    private var showCommitGraph = false

    public init(
        project: Project?,
        projectPath: @escaping (Project) -> String,
        loadItems: @escaping (Project, Int, Int) async throws -> [Item],
        loadUnpushedItems: @escaping (Project) async throws -> [UnpushedItem],
        itemID: @escaping (Item) -> String,
        itemParentIDs: @escaping (Item) -> [String],
        unpushedID: @escaping (UnpushedItem) -> String,
        updateUnpushed: @escaping (Int, [String]) -> Void,
        selectItem: @escaping (Item?) -> Void,
        loadLastSelectedID: @escaping (String) -> String?,
        logEvent: @escaping (CommitListHostLogEvent) -> Void = { _ in },
        refreshToken: Int = 0,
        refreshReason: String = "",
        @ViewBuilder workingStateContent: @escaping (Binding<Bool>) -> WorkingStateContent,
        @ViewBuilder rowContent: @escaping (Item, Bool, Int, CommitGraphPresentationRules.Row?, Int) -> RowContent
    ) {
        self.project = project
        self.projectPath = projectPath
        self.loadItems = loadItems
        self.loadUnpushedItems = loadUnpushedItems
        self.itemID = itemID
        self.itemParentIDs = itemParentIDs
        self.unpushedID = unpushedID
        self.updateUnpushed = updateUnpushed
        self.selectItem = selectItem
        self.loadLastSelectedID = loadLastSelectedID
        self.logEvent = logEvent
        self.refreshToken = refreshToken
        self.refreshReason = refreshReason
        self.workingStateContent = workingStateContent
        self.rowContent = rowContent
    }

    public var body: some View {
        let workspaceState = CommitListPaginationRules.workspacePresentationState(
            project: project,
            isLoading: loading,
            commitCount: items.count
        )
        let contentState = CommitListPaginationRules.contentPresentationState(
            isLoading: loading,
            commitCount: items.count
        )

        CommitListWorkspaceView(
            hasProject: workspaceState.hasProject,
            isInitialLoading: workspaceState.content.isInitialLoading,
            onGeometryAppear: onGeometryAppear(height:)
        ) {
            workingStateContent($loading)
        } historyContent: {
            CommitHistoryListView(
                isLoading: loading,
                hasRows: contentState.hasRows,
                showsCommitGraph: $showCommitGraph
            ) {
                CommitHistoryRowsView(
                    items: items,
                    firstItemID: CommitListPaginationRules.firstCommitID(in: items, id: itemID),
                    showsCommitGraph: showCommitGraph,
                    rowsByCommitID: graphRowsByItemID,
                    graphLaneCount: graphLaneCount,
                    hasMoreItems: hasMoreItems,
                    isLoading: loading,
                    isLoadingMoreScheduled: $isLoadingMoreScheduled,
                    id: itemID,
                    rowContent: rowContent,
                    schedule: { delay, action in
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                            action()
                        }
                    },
                    loadMore: loadMoreItems
                )
            }
        }
        .onAppear(perform: onAppear)
        .onChange(of: refreshToken) {
            refresh(refreshReason)
        }
    }
}

fileprivate enum CommitListBackgroundBuilder {
    struct AppendApplicationResult<Item: Sendable>: Sendable {
        let itemsToAppend: [Item]
        let appendState: CommitListPaginationRules.AppendResultState
        let graphState: CommitGraphPresentationRules.GraphState?
    }

    struct RefreshApplicationResult<Item: Sendable>: Sendable {
        let items: [Item]
        let resultState: CommitListPaginationRules.RefreshResultState
        let graphState: CommitGraphPresentationRules.GraphState
    }

    struct RestoreAppendApplicationResult<Item: Sendable>: Sendable {
        let itemsToAppend: [Item]
        let appendState: CommitListPaginationRules.AppendResultState
        let graphState: CommitGraphPresentationRules.GraphState?
        let selectedItem: Item?
        let shouldLoadMore: Bool
        let remainingAttempts: Int
    }

    struct UnsafeTransfer<Value>: @unchecked Sendable {
        let value: Value
    }

    static func runOffMainThread<Result: Sendable>(
        _ operation: @escaping () -> Result
    ) async -> Result {
        let result: Result = await withCheckedContinuation { (continuation: CheckedContinuation<Result, Never>) in
            let workItem = DispatchWorkItem {
                continuation.resume(returning: operation())
            }
            DispatchQueue.global(qos: .userInitiated).async(execute: workItem)
        }
        return result
    }

    static func makeAppendResult<Item>(
        existingItems: [Item],
        loadedItems: [Item],
        currentPage: Int,
        id: (Item) -> String,
        parentIDs: (Item) -> [String]
    ) -> AppendApplicationResult<Item> where Item: Sendable {
        let appendState = CommitListPaginationRules.appendResultState(
            existingItems: existingItems,
            newItems: loadedItems,
            currentPage: currentPage,
            id: id
        )
        let uniqueItems = CommitListPaginationRules.uniqueItems(
            from: loadedItems,
            keepingIDs: appendState.decision.uniqueNewIDs,
            id: id
        )
        let nextItems = appendState.appendsUniqueCommits ? existingItems + uniqueItems : existingItems
        let graphState = appendState.rebuildsGraphAfterAppend
            ? CommitGraphPresentationRules.graphState(from: nextItems, id: id, parentIDs: parentIDs)
            : nil

        return AppendApplicationResult(
            itemsToAppend: uniqueItems,
            appendState: appendState,
            graphState: graphState
        )
    }

    static func makeRefreshResult<Item>(
        items: [Item],
        unpushedIDs: [String],
        id: (Item) -> String,
        parentIDs: (Item) -> [String]
    ) -> RefreshApplicationResult<Item> where Item: Sendable {
        RefreshApplicationResult(
            items: items,
            resultState: CommitListPaginationRules.refreshSuccessResultState(unpushedIDs: unpushedIDs),
            graphState: CommitGraphPresentationRules.graphState(from: items, id: id, parentIDs: parentIDs)
        )
    }

    static func makeRestoreAppendResult<Item>(
        existingItems: [Item],
        loadedItems: [Item],
        currentPage: Int,
        targetID: String,
        hasMoreItemsForRestore: Bool,
        remainingAttempts: Int,
        id: (Item) -> String,
        parentIDs: (Item) -> [String]
    ) -> RestoreAppendApplicationResult<Item> where Item: Sendable {
        let appendState = CommitListPaginationRules.appendResultState(
            existingItems: existingItems,
            newItems: loadedItems,
            currentPage: currentPage,
            id: id
        )
        let uniqueItems = CommitListPaginationRules.uniqueItems(
            from: loadedItems,
            keepingIDs: appendState.decision.uniqueNewIDs,
            id: id
        )
        let nextItems = appendState.decision.hasMoreCommits ? existingItems + uniqueItems : existingItems
        let shouldRebuildGraph = appendState.rebuildsGraphAfterAppend || uniqueItems.isEmpty == false
        let restoreAction = CommitListPaginationRules.restoreAfterAppendAction(
            targetID: targetID,
            newItems: loadedItems,
            hasMoreCommits: hasMoreItemsForRestore,
            remainingAttempts: remainingAttempts,
            id: id
        )

        let selectedItem: Item?
        let shouldLoadMore: Bool
        let nextRemainingAttempts: Int
        switch restoreAction {
        case let .select(selectedID):
            selectedItem = loadedItems.first { id($0) == selectedID }
            shouldLoadMore = false
            nextRemainingAttempts = remainingAttempts
        case let .loadMore(_, remainingAttempts):
            selectedItem = nil
            shouldLoadMore = true
            nextRemainingAttempts = remainingAttempts
        case .none:
            selectedItem = nil
            shouldLoadMore = false
            nextRemainingAttempts = remainingAttempts
        }

        return RestoreAppendApplicationResult(
            itemsToAppend: uniqueItems,
            appendState: appendState,
            graphState: shouldRebuildGraph
                ? CommitGraphPresentationRules.graphState(from: nextItems, id: id, parentIDs: parentIDs)
                : nil,
            selectedItem: selectedItem,
            shouldLoadMore: shouldLoadMore,
            remainingAttempts: nextRemainingAttempts
        )
    }

    static func appendResult<Item>(
        existingItems: [Item],
        loadedItems: [Item],
        currentPage: Int,
        id: @escaping (Item) -> String,
        parentIDs: @escaping (Item) -> [String]
    ) async -> AppendApplicationResult<Item> where Item: Sendable {
        let existingItemsTransfer = UnsafeTransfer(value: existingItems)
        let loadedItemsTransfer = UnsafeTransfer(value: loadedItems)
        let itemIDTransfer = UnsafeTransfer(value: id)
        let itemParentIDsTransfer = UnsafeTransfer(value: parentIDs)

        return await runOffMainThread {
            makeAppendResult(
                existingItems: existingItemsTransfer.value,
                loadedItems: loadedItemsTransfer.value,
                currentPage: currentPage,
                id: itemIDTransfer.value,
                parentIDs: itemParentIDsTransfer.value
            )
        }
    }

    static func refreshResult<Item>(
        items: [Item],
        unpushedIDs: [String],
        id: @escaping (Item) -> String,
        parentIDs: @escaping (Item) -> [String]
    ) async -> RefreshApplicationResult<Item> where Item: Sendable {
        let itemsTransfer = UnsafeTransfer(value: items)
        let itemIDTransfer = UnsafeTransfer(value: id)
        let itemParentIDsTransfer = UnsafeTransfer(value: parentIDs)

        return await runOffMainThread {
            makeRefreshResult(
                items: itemsTransfer.value,
                unpushedIDs: unpushedIDs,
                id: itemIDTransfer.value,
                parentIDs: itemParentIDsTransfer.value
            )
        }
    }

    static func restoreAppendResult<Item>(
        existingItems: [Item],
        loadedItems: [Item],
        currentPage: Int,
        targetID: String,
        hasMoreItemsForRestore: Bool,
        remainingAttempts: Int,
        id: @escaping (Item) -> String,
        parentIDs: @escaping (Item) -> [String]
    ) async -> RestoreAppendApplicationResult<Item> where Item: Sendable {
        let existingItemsTransfer = UnsafeTransfer(value: existingItems)
        let loadedItemsTransfer = UnsafeTransfer(value: loadedItems)
        let itemIDTransfer = UnsafeTransfer(value: id)
        let itemParentIDsTransfer = UnsafeTransfer(value: parentIDs)

        return await runOffMainThread {
            makeRestoreAppendResult(
                existingItems: existingItemsTransfer.value,
                loadedItems: loadedItemsTransfer.value,
                currentPage: currentPage,
                targetID: targetID,
                hasMoreItemsForRestore: hasMoreItemsForRestore,
                remainingAttempts: remainingAttempts,
                id: itemIDTransfer.value,
                parentIDs: itemParentIDsTransfer.value
            )
        }
    }
}

private extension CommitListHostView {
    func rebuildGraphRows() {
        let graphState = CommitGraphPresentationRules.graphState(
            from: items,
            id: itemID,
            parentIDs: itemParentIDs
        )
        CommitGraphPresentationRules.performGraphState(
            graphState,
            setRowsByCommitID: { graphRowsByItemID = $0 },
            setLaneCount: { graphLaneCount = $0 }
        )
    }

    func applyPageState(_ state: CommitListPaginationRules.PageState) {
        CommitListPaginationRules.performPageState(
            state,
            setLoading: { loading = $0 },
            setCurrentPage: { currentPage = $0 },
            setHasMoreCommits: { hasMoreItems = $0 }
        )
    }

    func onGeometryAppear(height: CGFloat) {
        CommitListPaginationRules.performGeometryAppear(
            currentPageSize: pageSize,
            viewportHeight: height,
            setPageSize: { pageSize = $0 }
        )
    }

    func onAppear() {
        CommitListPaginationRules.performAppear(
            refresh: {
                refresh(CommitListPaginationRules.appearRefreshReason)
            },
            restoreSelection: restoreLastSelectedItem
        )
    }

    func setItem(_ item: Item?) {
        CommitListPaginationRules.performCommitSelection(item, select: selectItem)
    }

    func loadItemsInBackground(project: Project, page: Int, limit: Int) async throws -> [Item] {
        nonisolated(unsafe) let project = project
        nonisolated(unsafe) let loadItems = loadItems
        return try await loadItems(project, page, limit)
    }

    func loadMoreItems() {
        let requestState = CommitListPaginationRules.loadMoreRequestState(
            isLoading: loading,
            hasMoreCommits: hasMoreItems,
            currentPage: currentPage
        )
        CommitListPaginationRules.performRequiredProjectLoadMoreCommand(
            requestState,
            project: project,
            applyPageState: applyPageState
        ) { request in
            performLoadMoreItems(request)
        }
    }

    func performLoadMoreItems(_ request: CommitListPaginationRules.ProjectLoadMoreRequest<Project>) {
        // Extract project value before Task to avoid Sendable crossing
        nonisolated(unsafe) let project = request.project
        let page = currentPage
        let limit = pageSize
        let existingItems = items

        Task(priority: .userInitiated) { @MainActor in
            do {
                let loadedItems = try await loadItemsInBackground(project: project, page: page, limit: limit)
                let applicationResult = await appendApplicationResultInBackground(
                    existingItems: existingItems,
                    loadedItems: loadedItems,
                    currentPage: page
                )

                applyAppendApplicationResult(applicationResult)
            } catch {
                logEvent(.loadMoreFailure(error))
                applyPageState(CommitListPaginationRules.PageState(
                    isLoading: false,
                    currentPage: page,
                    hasMoreCommits: hasMoreItems
                ))
            }
        }
    }

    func refresh(_ reason: String) {
        CommitListPaginationRules.performRequiredProjectRefreshCommand(
            project: project,
            reason: reason,
            perform: performRefresh
        )
    }

    func performRefresh(_ request: CommitListPaginationRules.ProjectRefreshRequest<Project>) {
        // Extract project value before Task to avoid Sendable crossing
        nonisolated(unsafe) let project = request.project

        CommitListPaginationRules.performRefreshStart(
            cancelPreviousRefreshes: {
                currentRefreshTask?.cancel()
            },
            applyPageState: applyPageState
        )

        let limit = pageSize
        currentRefreshTask = Task(priority: .userInitiated) { @MainActor in
            do {
                try Task.checkCancellation()
                logEvent(.refresh(reason: request.request.reason))
                let refreshedItems = try await loadItemsInBackground(
                    project: project,
                    page: CommitListPaginationRules.initialPage,
                    limit: limit
                )
                let unpushedIDs = try await loadUnpushedItems(request.project).map(unpushedID)
                try Task.checkCancellation()
                let applicationResult = await refreshApplicationResultInBackground(
                    items: refreshedItems,
                    unpushedIDs: unpushedIDs
                )
                applyRefreshApplicationResult(applicationResult)
            } catch is CancellationError {
                return
            } catch {
                CommitListPaginationRules.performRefreshFailureResultState(
                    CommitListPaginationRules.refreshFailureResultState(),
                    setItems: { items = $0 },
                    rebuildGraph: rebuildGraphRows,
                    applyPageState: applyPageState
                )
            }
        }
    }

    func restoreLastSelectedItem() {
        CommitListPaginationRules.performRequiredProjectRestoreSelection(
            project: project,
            projectPath: projectPath,
            loadedItems: items,
            hasMoreCommits: hasMoreItems,
            id: itemID,
            loadLastSelectedID: loadLastSelectedID,
            select: setItem,
            loadMore: { targetID in
                loadMoreItemsUntilFound(targetID: targetID)
            }
        )
    }

    func loadMoreItemsUntilFound(
        targetID: String,
        maxAttempts: Int = CommitListPaginationRules.restoreSelectionMaxLoadMoreAttempts
    ) {
        let requestState = CommitListPaginationRules.loadMoreRequestState(
            isLoading: loading,
            hasMoreCommits: hasMoreItems,
            currentPage: currentPage,
            remainingAttempts: maxAttempts
        )
        CommitListPaginationRules.performRequiredProjectLoadMoreCommand(
            requestState,
            project: project,
            applyPageState: applyPageState
        ) { request in
            performRestoreLoadMore(targetID: targetID, maxAttempts: maxAttempts, request: request)
        }
    }

    func performRestoreLoadMore(
        targetID: String,
        maxAttempts: Int,
        request: CommitListPaginationRules.ProjectLoadMoreRequest<Project>
    ) {
        // Extract project value before Task to avoid Sendable crossing
        nonisolated(unsafe) let project = request.project
        let page = currentPage
        let limit = pageSize
        let existingItems = items
        let hasMoreItemsForRestore = hasMoreItems

        Task(priority: .userInitiated) { @MainActor in
            do {
                let loadedItems = try await loadItemsInBackground(project: project, page: page, limit: limit)
                let applicationResult = await restoreAppendApplicationResultInBackground(
                    existingItems: existingItems,
                    loadedItems: loadedItems,
                    currentPage: page,
                    targetID: targetID,
                    hasMoreItemsForRestore: hasMoreItemsForRestore,
                    remainingAttempts: maxAttempts - 1
                )
                applyRestoreAppendApplicationResult(applicationResult, targetID: targetID)
            } catch {
                applyPageState(CommitListPaginationRules.PageState(
                    isLoading: false,
                    currentPage: page,
                    hasMoreCommits: hasMoreItems
                ))
            }
        }
    }

    func appendApplicationResultInBackground(
        existingItems: [Item],
        loadedItems: [Item],
        currentPage: Int
    ) async -> CommitListBackgroundBuilder.AppendApplicationResult<Item> {
        let itemIDTransfer = CommitListBackgroundBuilder.UnsafeTransfer(value: itemID)
        let itemParentIDsTransfer = CommitListBackgroundBuilder.UnsafeTransfer(value: itemParentIDs)
        return await CommitListBackgroundBuilder.appendResult(
            existingItems: existingItems,
            loadedItems: loadedItems,
            currentPage: currentPage,
            id: itemIDTransfer.value,
            parentIDs: itemParentIDsTransfer.value
        )
    }

    func refreshApplicationResultInBackground(
        items: [Item],
        unpushedIDs: [String]
    ) async -> CommitListBackgroundBuilder.RefreshApplicationResult<Item> {
        let itemIDTransfer = CommitListBackgroundBuilder.UnsafeTransfer(value: itemID)
        let itemParentIDsTransfer = CommitListBackgroundBuilder.UnsafeTransfer(value: itemParentIDs)
        return await CommitListBackgroundBuilder.refreshResult(
            items: items,
            unpushedIDs: unpushedIDs,
            id: itemIDTransfer.value,
            parentIDs: itemParentIDsTransfer.value
        )
    }

    func restoreAppendApplicationResultInBackground(
        existingItems: [Item],
        loadedItems: [Item],
        currentPage: Int,
        targetID: String,
        hasMoreItemsForRestore: Bool,
        remainingAttempts: Int
    ) async -> CommitListBackgroundBuilder.RestoreAppendApplicationResult<Item> {
        let itemIDTransfer = CommitListBackgroundBuilder.UnsafeTransfer(value: itemID)
        let itemParentIDsTransfer = CommitListBackgroundBuilder.UnsafeTransfer(value: itemParentIDs)
        return await CommitListBackgroundBuilder.restoreAppendResult(
            existingItems: existingItems,
            loadedItems: loadedItems,
            currentPage: currentPage,
            targetID: targetID,
            hasMoreItemsForRestore: hasMoreItemsForRestore,
            remainingAttempts: remainingAttempts,
            id: itemIDTransfer.value,
            parentIDs: itemParentIDsTransfer.value
        )
    }

    func applyAppendApplicationResult(_ result: CommitListBackgroundBuilder.AppendApplicationResult<Item>) {
        if result.appendState.appendsUniqueCommits {
            items.append(contentsOf: result.itemsToAppend)
        } else if result.appendState.logsDuplicateWarning {
            logEvent(.duplicateLoadMore)
        }

        if let graphState = result.graphState {
            CommitGraphPresentationRules.performGraphState(
                graphState,
                setRowsByCommitID: { graphRowsByItemID = $0 },
                setLaneCount: { graphLaneCount = $0 }
            )
        }

        applyPageState(result.appendState.completionState)
    }

    func applyRefreshApplicationResult(_ result: CommitListBackgroundBuilder.RefreshApplicationResult<Item>) {
        CommitListPaginationRules.performRefreshSuccessResultState(
            result.resultState,
            items: result.items,
            updateUnpushed: updateUnpushed,
            setItems: { items = $0 },
            rebuildGraph: {
                CommitGraphPresentationRules.performGraphState(
                    result.graphState,
                    setRowsByCommitID: { graphRowsByItemID = $0 },
                    setLaneCount: { graphLaneCount = $0 }
                )
            },
            applyPageState: applyPageState
        )
    }

    func applyRestoreAppendApplicationResult(
        _ result: CommitListBackgroundBuilder.RestoreAppendApplicationResult<Item>,
        targetID: String
    ) {
        if result.appendState.decision.hasMoreCommits {
            items.append(contentsOf: result.itemsToAppend)
            currentPage = result.appendState.decision.nextPage

            if let selectedItem = result.selectedItem {
                setItem(selectedItem)
            } else if result.shouldLoadMore {
                loadMoreItemsUntilFound(targetID: targetID, maxAttempts: result.remainingAttempts)
            }
        }

        applyPageState(result.appendState.completionState)

        if let graphState = result.graphState {
            CommitGraphPresentationRules.performGraphState(
                graphState,
                setRowsByCommitID: { graphRowsByItemID = $0 },
                setLaneCount: { graphLaneCount = $0 }
            )
        }
    }
}
