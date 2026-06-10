import Foundation

public enum CommitListPaginationRules {
    public static let initialPage = 0
    public static let firstPageAfterRefresh = 1
    public static let hasMoreAfterRefreshStart = true
    public static let defaultPageSize = 50
    public static let showCommitGraphStorageKey = "App.ShowCommitGraph"
    public static let gitHeadChangedEventInfoKey = "headChanged"
    public static let loadMoreScheduleDelay: TimeInterval = 0.1
    public static let restoreSelectionMaxLoadMoreAttempts = 3
    public static let projectChangedRefreshReason = "Project Changed"
    public static let branchChangedRefreshReason = "Branch Changed"
    public static let commitSuccessRefreshReason = "GitCommitSuccess"
    public static let appearRefreshReason = "OnAppear"
    public static let pullSuccessRefreshReason = "GitPullSuccess"
    public static let gitDirectoryDidChangeRefreshReason = "GitDirectoryDidChange"
    public static let applicationWillBecomeActiveRefreshReason = "ApplicationWillBecomeActive"

    public static func duplicateLoadMoreWarningLogMessage() -> String {
        "⚠️ LoadMoreCommits - all commits were duplicates!"
    }

    public static func loadMoreFailureLogMessage(errorDescription: String) -> String {
        "❌ LoadMoreCommits error: \(errorDescription)"
    }

    public static func refreshLogMessage(reason: String) -> String {
        "🍋 Refresh(\(reason))"
    }

    public enum RestoreSelectionAction: Equatable, Sendable {
        case select(String?)
        case loadMore(targetID: String)
        case keepCurrent
    }

    public enum RestoreAfterAppendAction: Equatable, Sendable {
        case select(String)
        case loadMore(targetID: String, remainingAttempts: Int)
        case none
    }

    public enum RefreshEventAction: Equatable, Sendable {
        case refresh(reason: String)
        case none
    }

    public enum RefreshEvent: Equatable, Sendable {
        case projectChanged
        case branchChanged
        case commitSuccess
        case appear
        case pullSuccess
        case pushSuccess
        case gitDirectoryChanged(eventProjectPath: String, currentProjectPath: String?, didHeadChange: Bool)
        case applicationWillBecomeActive
    }

    public struct AppendDecision: Equatable, Sendable {
        public let uniqueNewIDs: [String]
        public let nextPage: Int
        public let hasMoreCommits: Bool

        public init(uniqueNewIDs: [String], nextPage: Int, hasMoreCommits: Bool) {
            self.uniqueNewIDs = uniqueNewIDs
            self.nextPage = nextPage
            self.hasMoreCommits = hasMoreCommits
        }
    }

    public struct AppendResultState: Equatable, Sendable {
        public let decision: AppendDecision
        public let appendsUniqueCommits: Bool
        public let logsDuplicateWarning: Bool
        public let rebuildsGraphAfterAppend: Bool
        public let completionState: PageState

        public init(
            decision: AppendDecision,
            appendsUniqueCommits: Bool,
            logsDuplicateWarning: Bool,
            rebuildsGraphAfterAppend: Bool,
            completionState: PageState
        ) {
            self.decision = decision
            self.appendsUniqueCommits = appendsUniqueCommits
            self.logsDuplicateWarning = logsDuplicateWarning
            self.rebuildsGraphAfterAppend = rebuildsGraphAfterAppend
            self.completionState = completionState
        }
    }

    public struct PageState: Equatable, Sendable {
        public let isLoading: Bool
        public let currentPage: Int
        public let hasMoreCommits: Bool

        public init(isLoading: Bool, currentPage: Int, hasMoreCommits: Bool) {
            self.isLoading = isLoading
            self.currentPage = currentPage
            self.hasMoreCommits = hasMoreCommits
        }
    }

    public struct RefreshRequest: Equatable, Sendable {
        public let reason: String

        public init(reason: String) {
            self.reason = reason
        }
    }

    public struct ProjectRefreshRequest<Project> {
        public let request: RefreshRequest
        public let project: Project

        public init(request: RefreshRequest, project: Project) {
            self.request = request
            self.project = project
        }
    }

    public struct LoadMoreRequestState: Equatable, Sendable {
        public let canRequest: Bool
        public let pageState: PageState

        public init(canRequest: Bool, pageState: PageState) {
            self.canRequest = canRequest
            self.pageState = pageState
        }
    }

    public struct ProjectLoadMoreRequest<Project> {
        public let state: LoadMoreRequestState
        public let project: Project

        public init(state: LoadMoreRequestState, project: Project) {
            self.state = state
            self.project = project
        }
    }

    public struct LoadMoreScheduleState: Equatable, Sendable {
        public let shouldSchedule: Bool
        public let delay: TimeInterval

        public init(shouldSchedule: Bool, delay: TimeInterval) {
            self.shouldSchedule = shouldSchedule
            self.delay = delay
        }
    }

    public struct ContentPresentationState: Equatable, Sendable {
        public let isInitialLoading: Bool
        public let hasRows: Bool

        public init(isInitialLoading: Bool, hasRows: Bool) {
            self.isInitialLoading = isInitialLoading
            self.hasRows = hasRows
        }
    }

    public struct WorkspacePresentationState: Equatable, Sendable {
        public let hasProject: Bool
        public let content: ContentPresentationState

        public init(hasProject: Bool, content: ContentPresentationState) {
            self.hasProject = hasProject
            self.content = content
        }
    }

    public struct RefreshResultState: Equatable, Sendable {
        public let pageState: PageState
        public let unpushedIDs: [String]
        public let clearsCommits: Bool

        public var unpushedCount: Int {
            unpushedIDs.count
        }

        public init(pageState: PageState, unpushedIDs: [String], clearsCommits: Bool) {
            self.pageState = pageState
            self.unpushedIDs = unpushedIDs
            self.clearsCommits = clearsCommits
        }
    }

    public struct RefreshLoadResult<Item> {
        public let items: [Item]
        public let unpushedIDs: [String]

        public init(items: [Item], unpushedIDs: [String]) {
            self.items = items
            self.unpushedIDs = unpushedIDs
        }
    }

    public struct RefreshLoadHandlers<Item, UnpushedCommit> {
        public let loadItems: (Int, Int) throws -> [Item]
        public let loadUnpushedItems: () async throws -> [UnpushedCommit]
        public let unpushedID: (UnpushedCommit) -> String

        public init(
            loadItems: @escaping (Int, Int) throws -> [Item],
            loadUnpushedItems: @escaping () async throws -> [UnpushedCommit],
            unpushedID: @escaping (UnpushedCommit) -> String
        ) {
            self.loadItems = loadItems
            self.loadUnpushedItems = loadUnpushedItems
            self.unpushedID = unpushedID
        }
    }

    public struct ProjectRefreshLoadHandlers<Project, Item, UnpushedCommit> {
        public let loadItems: (Project, Int, Int) throws -> [Item]
        public let loadUnpushedItems: (Project) async throws -> [UnpushedCommit]
        public let unpushedID: (UnpushedCommit) -> String

        public init(
            loadItems: @escaping (Project, Int, Int) throws -> [Item],
            loadUnpushedItems: @escaping (Project) async throws -> [UnpushedCommit],
            unpushedID: @escaping (UnpushedCommit) -> String
        ) {
            self.loadItems = loadItems
            self.loadUnpushedItems = loadUnpushedItems
            self.unpushedID = unpushedID
        }
    }

    public struct LoadMoreHandlers<Item> {
        public let loadItems: (Int, Int) throws -> [Item]
        public let id: (Item) -> String

        public init(
            loadItems: @escaping (Int, Int) throws -> [Item],
            id: @escaping (Item) -> String
        ) {
            self.loadItems = loadItems
            self.id = id
        }
    }

    public struct ProjectLoadMoreHandlers<Project, Item> {
        public let loadItems: (Project, Int, Int) throws -> [Item]
        public let id: (Item) -> String

        public init(
            loadItems: @escaping (Project, Int, Int) throws -> [Item],
            id: @escaping (Item) -> String
        ) {
            self.loadItems = loadItems
            self.id = id
        }
    }

    public static func pageSize(
        currentPageSize: Int,
        viewportHeight: Double,
        rowHeight: Double = 31,
        preloadRows: Int = 5
    ) -> Int {
        guard rowHeight > 0 else {
            return currentPageSize
        }

        let visibleRows = Int(ceil(viewportHeight / rowHeight))
        return max(currentPageSize, visibleRows + preloadRows)
    }

    public static func performGeometryAppear(
        currentPageSize: Int,
        viewportHeight: Double,
        setPageSize: (Int) -> Void
    ) {
        setPageSize(pageSize(currentPageSize: currentPageSize, viewportHeight: viewportHeight))
    }

    public static func performCommitSelection<Item>(
        _ item: Item?,
        select: (Item?) -> Void
    ) {
        select(item)
    }

    public static func performAppear(
        refresh: () -> Void,
        restoreSelection: () -> Void
    ) {
        refresh()
        restoreSelection()
    }

    public static func loadMoreThreshold(totalCount: Int) -> Int {
        max(totalCount - 10, Int(Double(totalCount) * 0.8))
    }

    public static func nextPageAfterAppending(currentPage: Int) -> Int {
        currentPage + 1
    }

    public static func shouldScheduleLoadMore(
        appearedIndex: Int,
        totalCount: Int,
        hasMoreCommits: Bool,
        isLoading: Bool,
        isAlreadyScheduled: Bool
    ) -> Bool {
        appearedIndex >= loadMoreThreshold(totalCount: totalCount) &&
            hasMoreCommits &&
            isLoading == false &&
            isAlreadyScheduled == false
    }

    public static func loadMoreScheduleState(
        appearedIndex: Int,
        totalCount: Int,
        hasMoreCommits: Bool,
        isLoading: Bool,
        isAlreadyScheduled: Bool
    ) -> LoadMoreScheduleState {
        LoadMoreScheduleState(
            shouldSchedule: shouldScheduleLoadMore(
                appearedIndex: appearedIndex,
                totalCount: totalCount,
                hasMoreCommits: hasMoreCommits,
                isLoading: isLoading,
                isAlreadyScheduled: isAlreadyScheduled
            ),
            delay: loadMoreScheduleDelay
        )
    }

    @discardableResult
    public static func performLoadMoreScheduleState(
        _ state: LoadMoreScheduleState,
        setScheduled: @escaping (Bool) -> Void,
        logScheduled: () -> Void,
        schedule: (TimeInterval, @escaping () -> Void) -> Void,
        logExecuting: @escaping () -> Void,
        loadMore: @escaping () -> Void
    ) -> Bool {
        guard state.shouldSchedule else {
            return false
        }

        setScheduled(true)
        logScheduled()
        schedule(state.delay) {
            setScheduled(false)
            logExecuting()
            loadMore()
        }
        return true
    }

    public static func firstCommitID(_ ids: [String]) -> String? {
        ids.first
    }

    public static func firstCommitID<Item>(in items: [Item], id: (Item) -> String) -> String? {
        items.first.map(id)
    }

    public static func contentPresentationState(isLoading: Bool, commitCount: Int) -> ContentPresentationState {
        ContentPresentationState(
            isInitialLoading: isLoading && commitCount == 0,
            hasRows: commitCount > 0
        )
    }

    public static func workspacePresentationState<Project>(
        project: Project?,
        isLoading: Bool,
        commitCount: Int
    ) -> WorkspacePresentationState {
        WorkspacePresentationState(
            hasProject: project != nil,
            content: contentPresentationState(isLoading: isLoading, commitCount: commitCount)
        )
    }

    public static func performPageState(
        _ state: PageState,
        setLoading: (Bool) -> Void,
        setCurrentPage: (Int) -> Void,
        setHasMoreCommits: (Bool) -> Void
    ) {
        setLoading(state.isLoading)
        setCurrentPage(state.currentPage)
        setHasMoreCommits(state.hasMoreCommits)
    }

    @discardableResult
    public static func performRequiredProject<Project>(
        _ project: Project?,
        perform: (Project) -> Void
    ) -> Bool {
        guard let project else {
            return false
        }

        perform(project)
        return true
    }

    @discardableResult
    public static func performRequiredProjectRefresh<Project>(
        project: Project?,
        reason: String,
        perform: (RefreshRequest, Project) -> Void
    ) -> Bool {
        guard let project else {
            return false
        }

        perform(RefreshRequest(reason: reason), project)
        return true
    }

    @discardableResult
    public static func performRequiredProjectRefreshCommand<Project>(
        project: Project?,
        reason: String,
        perform: (ProjectRefreshRequest<Project>) -> Void
    ) -> Bool {
        performRequiredProjectRefresh(
            project: project,
            reason: reason
        ) { request, project in
            perform(ProjectRefreshRequest(request: request, project: project))
        }
    }

    public static func refreshStartState() -> PageState {
        PageState(
            isLoading: true,
            currentPage: initialPage,
            hasMoreCommits: hasMoreAfterRefreshStart
        )
    }

    public static func refreshSuccessState() -> PageState {
        PageState(
            isLoading: false,
            currentPage: firstPageAfterRefresh,
            hasMoreCommits: hasMoreAfterRefreshStart
        )
    }

    public static func refreshFailureState() -> PageState {
        PageState(
            isLoading: false,
            currentPage: initialPage,
            hasMoreCommits: hasMoreAfterRefreshStart
        )
    }

    public static func refreshSuccessResultState(unpushedIDs: [String]) -> RefreshResultState {
        RefreshResultState(
            pageState: refreshSuccessState(),
            unpushedIDs: unpushedIDs,
            clearsCommits: false
        )
    }

    public static func refreshFailureResultState() -> RefreshResultState {
        RefreshResultState(
            pageState: refreshFailureState(),
            unpushedIDs: [],
            clearsCommits: true
        )
    }

    public static func performRefreshLoad<Item, UnpushedCommit>(
        pageSize: Int,
        loadItems: (Int, Int) throws -> [Item],
        loadUnpushedItems: () async throws -> [UnpushedCommit],
        unpushedID: (UnpushedCommit) -> String
    ) async throws -> RefreshLoadResult<Item> {
        try Task.checkCancellation()

        let items = try loadItems(initialPage, pageSize)
        let unpushedIDs = try await loadUnpushedItems().map(unpushedID)

        try Task.checkCancellation()
        return RefreshLoadResult(items: items, unpushedIDs: unpushedIDs)
    }

    public static func performRefreshLoad<Item, UnpushedCommit>(
        pageSize: Int,
        handlers: RefreshLoadHandlers<Item, UnpushedCommit>
    ) async throws -> RefreshLoadResult<Item> {
        try await performRefreshLoad(
            pageSize: pageSize,
            loadItems: handlers.loadItems,
            loadUnpushedItems: handlers.loadUnpushedItems,
            unpushedID: handlers.unpushedID
        )
    }

    public static func performRefreshOperation<Item, UnpushedCommit>(
        pageSize: Int,
        loadItems: (Int, Int) throws -> [Item],
        loadUnpushedItems: () async throws -> [UnpushedCommit],
        unpushedID: (UnpushedCommit) -> String,
        logRefresh: () async -> Void,
        applySuccess: ([Item], RefreshResultState) async -> Void,
        applyFailure: (RefreshResultState) async -> Void
    ) async {
        do {
            try Task.checkCancellation()
            await logRefresh()
            let result = try await performRefreshLoad(
                pageSize: pageSize,
                loadItems: loadItems,
                loadUnpushedItems: loadUnpushedItems,
                unpushedID: unpushedID
            )
            await applySuccess(
                result.items,
                refreshSuccessResultState(unpushedIDs: result.unpushedIDs)
            )
        } catch is CancellationError {
            return
        } catch {
            await applyFailure(refreshFailureResultState())
        }
    }

    public static func performRefreshOperation<Item, UnpushedCommit>(
        pageSize: Int,
        handlers: RefreshLoadHandlers<Item, UnpushedCommit>,
        logRefresh: () async -> Void,
        applySuccess: ([Item], RefreshResultState) async -> Void,
        applyFailure: (RefreshResultState) async -> Void
    ) async {
        await performRefreshOperation(
            pageSize: pageSize,
            loadItems: handlers.loadItems,
            loadUnpushedItems: handlers.loadUnpushedItems,
            unpushedID: handlers.unpushedID,
            logRefresh: logRefresh,
            applySuccess: applySuccess,
            applyFailure: applyFailure
        )
    }

    public static func refreshLoadHandlers<Project, Item, UnpushedCommit>(
        for project: Project,
        handlers: ProjectRefreshLoadHandlers<Project, Item, UnpushedCommit>
    ) -> RefreshLoadHandlers<Item, UnpushedCommit> {
        RefreshLoadHandlers(
            loadItems: { page, limit in
                try handlers.loadItems(project, page, limit)
            },
            loadUnpushedItems: {
                try await handlers.loadUnpushedItems(project)
            },
            unpushedID: handlers.unpushedID
        )
    }

    public static func performRefreshOperation<Project, Item, UnpushedCommit>(
        request: ProjectRefreshRequest<Project>,
        pageSize: Int,
        handlers: ProjectRefreshLoadHandlers<Project, Item, UnpushedCommit>,
        logRefresh: () async -> Void,
        applySuccess: ([Item], RefreshResultState) async -> Void,
        applyFailure: (RefreshResultState) async -> Void
    ) async {
        await performRefreshOperation(
            pageSize: pageSize,
            handlers: refreshLoadHandlers(for: request.project, handlers: handlers),
            logRefresh: logRefresh,
            applySuccess: applySuccess,
            applyFailure: applyFailure
        )
    }

    public static func performRefreshSuccessResultState<Item>(
        _ state: RefreshResultState,
        items: [Item],
        updateUnpushed: (Int, [String]) -> Void,
        setItems: ([Item]) -> Void,
        rebuildGraph: () -> Void,
        applyPageState: (PageState) -> Void
    ) {
        updateUnpushed(state.unpushedCount, state.unpushedIDs)
        setItems(items)
        rebuildGraph()
        applyPageState(state.pageState)
    }

    public static func performRefreshFailureResultState<Item>(
        _ state: RefreshResultState,
        setItems: ([Item]) -> Void,
        rebuildGraph: () -> Void,
        applyPageState: (PageState) -> Void
    ) {
        if state.clearsCommits {
            setItems([])
        }
        rebuildGraph()
        applyPageState(state.pageState)
    }

    public static func performRefreshStart(
        cancelPreviousRefreshes: () -> Void,
        applyPageState: (PageState) -> Void
    ) {
        cancelPreviousRefreshes()
        applyPageState(refreshStartState())
    }

    public static func loadingState(currentPage: Int, hasMoreCommits: Bool) -> PageState {
        PageState(
            isLoading: true,
            currentPage: currentPage,
            hasMoreCommits: hasMoreCommits
        )
    }

    public static func loadMoreRequestState(
        isLoading: Bool,
        hasMoreCommits: Bool,
        currentPage: Int,
        remainingAttempts: Int = 1
    ) -> LoadMoreRequestState {
        LoadMoreRequestState(
            canRequest: isLoading == false && hasMoreCommits && remainingAttempts > 0,
            pageState: loadingState(currentPage: currentPage, hasMoreCommits: hasMoreCommits)
        )
    }

    public static func performLoadMoreRequestState(
        _ state: LoadMoreRequestState,
        applyPageState: (PageState) -> Void
    ) -> Bool {
        guard state.canRequest else {
            return false
        }

        applyPageState(state.pageState)
        return true
    }

    @discardableResult
    public static func performRequiredProjectLoadMoreRequest<Project>(
        _ state: LoadMoreRequestState,
        project: Project?,
        applyPageState: (PageState) -> Void,
        perform: (Project) -> Void
    ) -> Bool {
        guard let project,
              performLoadMoreRequestState(state, applyPageState: applyPageState) else {
            return false
        }

        perform(project)
        return true
    }

    @discardableResult
    public static func performRequiredProjectLoadMoreCommand<Project>(
        _ state: LoadMoreRequestState,
        project: Project?,
        applyPageState: (PageState) -> Void,
        perform: (ProjectLoadMoreRequest<Project>) -> Void
    ) -> Bool {
        guard let project,
              performLoadMoreRequestState(state, applyPageState: applyPageState) else {
            return false
        }

        perform(ProjectLoadMoreRequest(state: state, project: project))
        return true
    }

    public static func performLoadMoreLoad<Item>(
        page: Int,
        pageSize: Int,
        loadItems: (Int, Int) throws -> [Item]
    ) async throws -> [Item] {
        try Task.checkCancellation()
        let items = try loadItems(page, pageSize)
        try Task.checkCancellation()
        return items
    }

    public static func performLoadMoreLoad<Item>(
        page: Int,
        pageSize: Int,
        handlers: LoadMoreHandlers<Item>
    ) async throws -> [Item] {
        try await performLoadMoreLoad(
            page: page,
            pageSize: pageSize,
            loadItems: handlers.loadItems
        )
    }

    public static func performLoadMoreOperation<Item>(
        page: Int,
        pageSize: Int,
        existingItems: [Item],
        currentPage: Int,
        hasMoreCommits: Bool,
        loadItems: (Int, Int) throws -> [Item],
        id: (Item) -> String,
        applyAppend: ([Item], AppendResultState) async -> Void,
        applyFailure: (PageState) async -> Void,
        logFailure: (Error) async -> Void
    ) async {
        do {
            let newItems = try await performLoadMoreLoad(
                page: page,
                pageSize: pageSize,
                loadItems: loadItems
            )
            await applyAppend(
                newItems,
                appendResultState(
                    existingItems: existingItems,
                    newItems: newItems,
                    currentPage: currentPage,
                    id: id
                )
            )
        } catch is CancellationError {
            return
        } catch {
            await applyFailure(stoppedState(
                currentPage: currentPage,
                hasMoreCommits: hasMoreCommits
            ))
            await logFailure(error)
        }
    }

    public static func performLoadMoreOperation<Item>(
        page: Int,
        pageSize: Int,
        existingItems: [Item],
        currentPage: Int,
        hasMoreCommits: Bool,
        handlers: LoadMoreHandlers<Item>,
        applyAppend: ([Item], AppendResultState) async -> Void,
        applyFailure: (PageState) async -> Void,
        logFailure: (Error) async -> Void
    ) async {
        await performLoadMoreOperation(
            page: page,
            pageSize: pageSize,
            existingItems: existingItems,
            currentPage: currentPage,
            hasMoreCommits: hasMoreCommits,
            loadItems: handlers.loadItems,
            id: handlers.id,
            applyAppend: applyAppend,
            applyFailure: applyFailure,
            logFailure: logFailure
        )
    }

    public static func loadMoreHandlers<Project, Item>(
        for project: Project,
        handlers: ProjectLoadMoreHandlers<Project, Item>
    ) -> LoadMoreHandlers<Item> {
        LoadMoreHandlers(
            loadItems: { page, limit in
                try handlers.loadItems(project, page, limit)
            },
            id: handlers.id
        )
    }

    public static func performLoadMoreOperation<Project, Item>(
        request: ProjectLoadMoreRequest<Project>,
        page: Int,
        pageSize: Int,
        existingItems: [Item],
        currentPage: Int,
        hasMoreCommits: Bool,
        handlers: ProjectLoadMoreHandlers<Project, Item>,
        applyAppend: ([Item], AppendResultState) async -> Void,
        applyFailure: (PageState) async -> Void,
        logFailure: (Error) async -> Void
    ) async {
        await performLoadMoreOperation(
            page: page,
            pageSize: pageSize,
            existingItems: existingItems,
            currentPage: currentPage,
            hasMoreCommits: hasMoreCommits,
            handlers: loadMoreHandlers(for: request.project, handlers: handlers),
            applyAppend: applyAppend,
            applyFailure: applyFailure,
            logFailure: logFailure
        )
    }

    public static func performRestoreLoadMoreOperation<Item>(
        targetID: String,
        remainingAttempts: Int,
        page: Int,
        pageSize: Int,
        existingItems: [Item],
        currentPage: Int,
        hasMoreCommits: Bool,
        loadItems: (Int, Int) throws -> [Item],
        id: (Item) -> String,
        applyAppend: ([Item], AppendResultState, String, Int) async -> Void,
        applyFailure: (PageState) async -> Void
    ) async {
        await performLoadMoreOperation(
            page: page,
            pageSize: pageSize,
            existingItems: existingItems,
            currentPage: currentPage,
            hasMoreCommits: hasMoreCommits,
            loadItems: loadItems,
            id: id,
            applyAppend: { newItems, appendState in
                await applyAppend(newItems, appendState, targetID, remainingAttempts)
            },
            applyFailure: applyFailure,
            logFailure: { _ in }
        )
    }

    public static func performRestoreLoadMoreOperation<Item>(
        targetID: String,
        remainingAttempts: Int,
        page: Int,
        pageSize: Int,
        existingItems: [Item],
        currentPage: Int,
        hasMoreCommits: Bool,
        handlers: LoadMoreHandlers<Item>,
        applyAppend: ([Item], AppendResultState, String, Int) async -> Void,
        applyFailure: (PageState) async -> Void
    ) async {
        await performRestoreLoadMoreOperation(
            targetID: targetID,
            remainingAttempts: remainingAttempts,
            page: page,
            pageSize: pageSize,
            existingItems: existingItems,
            currentPage: currentPage,
            hasMoreCommits: hasMoreCommits,
            loadItems: handlers.loadItems,
            id: handlers.id,
            applyAppend: applyAppend,
            applyFailure: applyFailure
        )
    }

    public static func performRestoreLoadMoreOperation<Project, Item>(
        request: ProjectLoadMoreRequest<Project>,
        targetID: String,
        remainingAttempts: Int,
        page: Int,
        pageSize: Int,
        existingItems: [Item],
        currentPage: Int,
        hasMoreCommits: Bool,
        handlers: ProjectLoadMoreHandlers<Project, Item>,
        applyAppend: ([Item], AppendResultState, String, Int) async -> Void,
        applyFailure: (PageState) async -> Void
    ) async {
        await performRestoreLoadMoreOperation(
            targetID: targetID,
            remainingAttempts: remainingAttempts,
            page: page,
            pageSize: pageSize,
            existingItems: existingItems,
            currentPage: currentPage,
            hasMoreCommits: hasMoreCommits,
            handlers: loadMoreHandlers(for: request.project, handlers: handlers),
            applyAppend: applyAppend,
            applyFailure: applyFailure
        )
    }

    public static func appendCompletionState(from decision: AppendDecision, currentPage: Int) -> PageState {
        PageState(
            isLoading: false,
            currentPage: decision.hasMoreCommits ? decision.nextPage : currentPage,
            hasMoreCommits: decision.hasMoreCommits
        )
    }

    public static func shouldAppendCommits(from decision: AppendDecision) -> Bool {
        decision.hasMoreCommits && decision.uniqueNewIDs.isEmpty == false
    }

    public static func shouldRebuildGraphAfterAppend(decision: AppendDecision, didAppendUniqueCommits: Bool) -> Bool {
        didAppendUniqueCommits || decision.hasMoreCommits == false
    }

    public static func stoppedState(currentPage: Int, hasMoreCommits: Bool) -> PageState {
        PageState(
            isLoading: false,
            currentPage: currentPage,
            hasMoreCommits: hasMoreCommits
        )
    }

    public static func performLoadMoreFailure(
        currentPage: Int,
        hasMoreCommits: Bool,
        applyPageState: (PageState) -> Void
    ) {
        applyPageState(stoppedState(
            currentPage: currentPage,
            hasMoreCommits: hasMoreCommits
        ))
    }

    public static func uniqueNewIDs(existingIDs: [String], newIDs: [String]) -> [String] {
        let existing = Set(existingIDs)
        return newIDs.filter { existing.contains($0) == false }
    }

    public static func uniqueItems<Item>(
        from items: [Item],
        keepingIDs ids: [String],
        id: (Item) -> String
    ) -> [Item] {
        let idSet = Set(ids)
        return items.filter { idSet.contains(id($0)) }
    }

    public static func firstItem<Item>(
        matchingID targetID: String,
        in items: [Item],
        id: (Item) -> String
    ) -> Item? {
        items.first { id($0) == targetID }
    }

    public static func selectedItem<Item>(
        for action: RestoreSelectionAction,
        in items: [Item],
        id: (Item) -> String
    ) -> Item? {
        guard case let .select(selectedID) = action,
              let selectedID else {
            return nil
        }

        return firstItem(matchingID: selectedID, in: items, id: id)
    }

    public static func selectedItem<Item>(
        for action: RestoreAfterAppendAction,
        in items: [Item],
        id: (Item) -> String
    ) -> Item? {
        guard case let .select(selectedID) = action else {
            return nil
        }

        return firstItem(matchingID: selectedID, in: items, id: id)
    }

    public static func performRestoreSelectionAction<Item>(
        _ action: RestoreSelectionAction,
        in items: [Item],
        id: (Item) -> String,
        select: (Item?) -> Void,
        loadMore: (String) -> Void
    ) {
        switch action {
        case .select:
            select(selectedItem(for: action, in: items, id: id))
        case let .loadMore(targetID):
            loadMore(targetID)
        case .keepCurrent:
            break
        }
    }

    @discardableResult
    public static func performRequiredProjectRestoreSelection<Project, Item>(
        project: Project?,
        projectPath: (Project) -> String,
        loadedItems: [Item],
        hasMoreCommits: Bool,
        id: (Item) -> String,
        loadLastSelectedID: (String) -> String?,
        select: (Item?) -> Void,
        loadMore: (String) -> Void
    ) -> Bool {
        guard let project else {
            return false
        }

        let action = restoreSelectionAction(
            lastSelectedID: loadLastSelectedID(projectPath(project)),
            loadedItems: loadedItems,
            hasMoreCommits: hasMoreCommits,
            id: id
        )

        performRestoreSelectionAction(
            action,
            in: loadedItems,
            id: id,
            select: select,
            loadMore: loadMore
        )
        return true
    }

    public static func performRestoreAfterAppendAction<Item>(
        _ action: RestoreAfterAppendAction,
        in items: [Item],
        id: (Item) -> String,
        select: (Item) -> Void,
        loadMore: (String, Int) -> Void
    ) {
        switch action {
        case .select:
            if let item = selectedItem(for: action, in: items, id: id) {
                select(item)
            }
        case let .loadMore(targetID, remainingAttempts):
            loadMore(targetID, remainingAttempts)
        case .none:
            break
        }
    }

    public static func appendDecision(
        existingIDs: [String],
        newIDs: [String],
        currentPage: Int
    ) -> AppendDecision {
        guard newIDs.isEmpty == false else {
            return AppendDecision(
                uniqueNewIDs: [],
                nextPage: currentPage,
                hasMoreCommits: false
            )
        }

        return AppendDecision(
            uniqueNewIDs: uniqueNewIDs(existingIDs: existingIDs, newIDs: newIDs),
            nextPage: nextPageAfterAppending(currentPage: currentPage),
            hasMoreCommits: true
        )
    }

    public static func appendResultState(
        existingIDs: [String],
        newIDs: [String],
        currentPage: Int
    ) -> AppendResultState {
        let decision = appendDecision(
            existingIDs: existingIDs,
            newIDs: newIDs,
            currentPage: currentPage
        )
        let appendsUniqueCommits = shouldAppendCommits(from: decision)

        return AppendResultState(
            decision: decision,
            appendsUniqueCommits: appendsUniqueCommits,
            logsDuplicateWarning: decision.hasMoreCommits && decision.uniqueNewIDs.isEmpty,
            rebuildsGraphAfterAppend: shouldRebuildGraphAfterAppend(
                decision: decision,
                didAppendUniqueCommits: appendsUniqueCommits
            ),
            completionState: appendCompletionState(from: decision, currentPage: currentPage)
        )
    }

    public static func appendResultState<Item>(
        existingItems: [Item],
        newItems: [Item],
        currentPage: Int,
        id: (Item) -> String
    ) -> AppendResultState {
        appendResultState(
            existingIDs: existingItems.map(id),
            newIDs: newItems.map(id),
            currentPage: currentPage
        )
    }

    public static func performAppendResultState<Item>(
        _ state: AppendResultState,
        newItems: [Item],
        id: (Item) -> String,
        appendItems: ([Item]) -> Void,
        rebuildGraph: () -> Void,
        logDuplicateWarning: () -> Void,
        applyPageState: (PageState) -> Void
    ) {
        if state.appendsUniqueCommits {
            appendItems(uniqueItems(
                from: newItems,
                keepingIDs: state.decision.uniqueNewIDs,
                id: id
            ))
        } else if state.logsDuplicateWarning {
            logDuplicateWarning()
        }

        if state.rebuildsGraphAfterAppend {
            rebuildGraph()
        }

        applyPageState(state.completionState)
    }

    public static func performAppendResultForRestore<Item>(
        _ state: AppendResultState,
        newItems: [Item],
        targetID: String,
        hasMoreCommitsForRestore: Bool,
        remainingAttempts: Int,
        id: (Item) -> String,
        appendItems: ([Item]) -> Void,
        setCurrentPage: (Int) -> Void,
        rebuildGraph: () -> Void,
        select: (Item) -> Void,
        loadMore: (String, Int) -> Void,
        applyPageState: (PageState) -> Void
    ) {
        var didAppendUniqueCommits = false

        if state.decision.hasMoreCommits {
            let uniqueNewItems = uniqueItems(
                from: newItems,
                keepingIDs: state.decision.uniqueNewIDs,
                id: id
            )
            appendItems(uniqueNewItems)
            didAppendUniqueCommits = uniqueNewItems.isEmpty == false

            if didAppendUniqueCommits {
                rebuildGraph()
            }

            setCurrentPage(state.decision.nextPage)

            let restoreAction = restoreAfterAppendAction(
                targetID: targetID,
                newItems: newItems,
                hasMoreCommits: hasMoreCommitsForRestore,
                remainingAttempts: remainingAttempts,
                id: id
            )
            performRestoreAfterAppendAction(
                restoreAction,
                in: newItems,
                id: id,
                select: select,
                loadMore: loadMore
            )
        }

        applyPageState(state.completionState)

        if state.rebuildsGraphAfterAppend && didAppendUniqueCommits == false {
            rebuildGraph()
        }
    }

    public static func restoreSelectionAction(
        lastSelectedID: String?,
        loadedIDs: [String],
        hasMoreCommits: Bool
    ) -> RestoreSelectionAction {
        guard let lastSelectedID else {
            return .select(loadedIDs.first)
        }

        if loadedIDs.contains(lastSelectedID) {
            return .select(lastSelectedID)
        }

        if hasMoreCommits {
            return .loadMore(targetID: lastSelectedID)
        }

        return .keepCurrent
    }

    public static func restoreSelectionAction<Item>(
        lastSelectedID: String?,
        loadedItems: [Item],
        hasMoreCommits: Bool,
        id: (Item) -> String
    ) -> RestoreSelectionAction {
        restoreSelectionAction(
            lastSelectedID: lastSelectedID,
            loadedIDs: loadedItems.map(id),
            hasMoreCommits: hasMoreCommits
        )
    }

    public static func restoreAfterAppendAction(
        targetID: String,
        newIDs: [String],
        hasMoreCommits: Bool,
        remainingAttempts: Int
    ) -> RestoreAfterAppendAction {
        if newIDs.contains(targetID) {
            return .select(targetID)
        }

        if hasMoreCommits && remainingAttempts > 0 {
            return .loadMore(targetID: targetID, remainingAttempts: remainingAttempts)
        }

        return .none
    }

    public static func restoreAfterAppendAction<Item>(
        targetID: String,
        newItems: [Item],
        hasMoreCommits: Bool,
        remainingAttempts: Int,
        id: (Item) -> String
    ) -> RestoreAfterAppendAction {
        restoreAfterAppendAction(
            targetID: targetID,
            newIDs: newItems.map(id),
            hasMoreCommits: hasMoreCommits,
            remainingAttempts: remainingAttempts
        )
    }

    public static func refreshActionOnProjectChanged() -> RefreshEventAction {
        .refresh(reason: projectChangedRefreshReason)
    }

    public static func refreshActionOnBranchChanged() -> RefreshEventAction {
        .refresh(reason: branchChangedRefreshReason)
    }

    public static func refreshActionOnCommitSuccess() -> RefreshEventAction {
        .refresh(reason: commitSuccessRefreshReason)
    }

    public static func refreshActionOnAppear() -> RefreshEventAction {
        .refresh(reason: appearRefreshReason)
    }

    public static func refreshActionOnPullSuccess() -> RefreshEventAction {
        .refresh(reason: pullSuccessRefreshReason)
    }

    public static func refreshActionOnPushSuccess() -> RefreshEventAction {
        .none
    }

    public static func isCurrentProject(eventProjectPath: String, currentProjectPath: String?) -> Bool {
        eventProjectPath == currentProjectPath
    }

    public static func refreshActionOnGitDirectoryChanged(
        isCurrentProject: Bool,
        didHeadChange: Bool
    ) -> RefreshEventAction {
        isCurrentProject && didHeadChange ? .refresh(reason: gitDirectoryDidChangeRefreshReason) : .none
    }

    public static func refreshActionOnGitDirectoryChanged(
        eventProjectPath: String,
        currentProjectPath: String?,
        didHeadChange: Bool
    ) -> RefreshEventAction {
        refreshActionOnGitDirectoryChanged(
            isCurrentProject: isCurrentProject(
                eventProjectPath: eventProjectPath,
                currentProjectPath: currentProjectPath
            ),
            didHeadChange: didHeadChange
        )
    }

    public static func refreshActionOnGitDirectoryChanged<Project>(
        eventProjectPath: String,
        currentProject: Project?,
        currentProjectPath: (Project) -> String,
        didHeadChange: Bool
    ) -> RefreshEventAction {
        refreshActionOnGitDirectoryChanged(
            eventProjectPath: eventProjectPath,
            currentProjectPath: currentProject.map(currentProjectPath),
            didHeadChange: didHeadChange
        )
    }

    public static func refreshActionOnApplicationWillBecomeActive() -> RefreshEventAction {
        .refresh(reason: applicationWillBecomeActiveRefreshReason)
    }

    public static func refreshAction(for event: RefreshEvent) -> RefreshEventAction {
        switch event {
        case .projectChanged:
            return refreshActionOnProjectChanged()
        case .branchChanged:
            return refreshActionOnBranchChanged()
        case .commitSuccess:
            return refreshActionOnCommitSuccess()
        case .appear:
            return refreshActionOnAppear()
        case .pullSuccess:
            return refreshActionOnPullSuccess()
        case .pushSuccess:
            return refreshActionOnPushSuccess()
        case let .gitDirectoryChanged(eventProjectPath, currentProjectPath, didHeadChange):
            return refreshActionOnGitDirectoryChanged(
                eventProjectPath: eventProjectPath,
                currentProjectPath: currentProjectPath,
                didHeadChange: didHeadChange
            )
        case .applicationWillBecomeActive:
            return refreshActionOnApplicationWillBecomeActive()
        }
    }

    public static func refreshAction<Project>(
        gitDirectoryChangedEventProjectPath eventProjectPath: String,
        currentProject: Project?,
        currentProjectPath: (Project) -> String,
        didHeadChange: Bool
    ) -> RefreshEventAction {
        refreshAction(for: .gitDirectoryChanged(
            eventProjectPath: eventProjectPath,
            currentProjectPath: currentProject.map(currentProjectPath),
            didHeadChange: didHeadChange
        ))
    }

    public static func performRefreshAction(
        _ action: RefreshEventAction,
        refresh: (String) -> Void
    ) {
        switch action {
        case let .refresh(reason):
            refresh(reason)
        case .none:
            break
        }
    }

    public static func performRefreshEvent(
        _ event: RefreshEvent,
        refresh: (String) -> Void
    ) {
        performRefreshAction(refreshAction(for: event), refresh: refresh)
    }

    public static func performGitDirectoryChangedRefreshEvent<Project>(
        eventProjectPath: String,
        currentProject: Project?,
        currentProjectPath: (Project) -> String,
        didHeadChange: Bool,
        refresh: (String) -> Void
    ) {
        performRefreshAction(
            refreshAction(
                gitDirectoryChangedEventProjectPath: eventProjectPath,
                currentProject: currentProject,
                currentProjectPath: currentProjectPath,
                didHeadChange: didHeadChange
            ),
            refresh: refresh
        )
    }
}
