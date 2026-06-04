import SwiftUI

public enum CommitListHostLogEvent {
    case refresh(reason: String)
    case loadMoreFailure(Error)
    case duplicateLoadMore
}

public struct CommitListHostView<Project, Item, UnpushedItem, WorkingStateContent: View, RowContent: View>: View {
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
        let existingIDs = Set(existingItems.map(itemID))

        Task(priority: .userInitiated) { @MainActor in
            do {
                let loadedItems = try await loadItemsInBackground(project: project, page: page, limit: limit)
                let uniqueItems = loadedItems.filter { existingIDs.contains(itemID($0)) == false }
                let appendState = CommitListPaginationRules.appendResultState(
                    existingIDs: existingItems.map(itemID),
                    newIDs: loadedItems.map(itemID),
                    currentPage: page
                )

                CommitListPaginationRules.performAppendResultState(
                    appendState,
                    newItems: uniqueItems,
                    id: itemID,
                    appendItems: { items.append(contentsOf: $0) },
                    rebuildGraph: rebuildGraphRows,
                    logDuplicateWarning: {
                        logEvent(.duplicateLoadMore)
                    },
                    applyPageState: applyPageState
                )
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
                CommitListPaginationRules.performRefreshSuccessResultState(
                    CommitListPaginationRules.refreshSuccessResultState(unpushedIDs: unpushedIDs),
                    items: refreshedItems,
                    updateUnpushed: updateUnpushed,
                    setItems: { items = $0 },
                    rebuildGraph: rebuildGraphRows,
                    applyPageState: applyPageState
                )
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
        let existingIDs = Set(existingItems.map(itemID))

        Task(priority: .userInitiated) { @MainActor in
            do {
                let loadedItems = try await loadItemsInBackground(project: project, page: page, limit: limit)
                let uniqueItems = loadedItems.filter { existingIDs.contains(itemID($0)) == false }
                let appendState = CommitListPaginationRules.appendResultState(
                    existingIDs: existingItems.map(itemID),
                    newIDs: loadedItems.map(itemID),
                    currentPage: page
                )
                CommitListPaginationRules.performAppendResultForRestore(
                    appendState,
                    newItems: uniqueItems,
                    targetID: targetID,
                    hasMoreCommitsForRestore: hasMoreItems,
                    remainingAttempts: maxAttempts - 1,
                    id: itemID,
                    appendItems: { items.append(contentsOf: $0) },
                    setCurrentPage: { currentPage = $0 },
                    rebuildGraph: rebuildGraphRows,
                    select: setItem,
                    loadMore: { targetID, remainingAttempts in
                        loadMoreItemsUntilFound(targetID: targetID, maxAttempts: remainingAttempts)
                    },
                    applyPageState: applyPageState
                )
            } catch {
                applyPageState(CommitListPaginationRules.PageState(
                    isLoading: false,
                    currentPage: page,
                    hasMoreCommits: hasMoreItems
                ))
            }
        }
    }
}
