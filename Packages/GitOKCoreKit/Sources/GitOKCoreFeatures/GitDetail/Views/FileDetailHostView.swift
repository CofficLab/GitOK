import AppKit
import SwiftUI

public enum FileDetailHostEvent {
    case error(String)
    case update(reason: String)
    case textPreviewFailure(issueMessage: String)
    case diffFailure(errorDescription: String)
}

public struct FileDetailHostView<Project, File, SelectedCommit, LoadedCommit>: View {
    private let project: Project?
    private let file: File?
    private let selectedCommit: SelectedCommit?
    private let filePath: (File) -> String
    private let isImage: (File) -> Bool
    private let isBinary: (File) -> Bool
    private let changeType: (File) -> String
    private let existingPatch: (File) -> String
    private let selectedCommitHash: (SelectedCommit) -> String
    private let loadCurrentCommitData: (Project, File, String) async throws -> Data
    private let loadCurrentWorktreeData: (Project, File) async throws -> Data
    private let loadCommits: (Project) async throws -> [LoadedCommit]
    private let loadedCommitHash: (LoadedCommit) -> String
    private let loadedParentHashes: (LoadedCommit) -> [String]
    private let loadHeadHash: (Project) async -> String?
    private let loadPreviousCommitData: (Project, File, String) async throws -> Data
    private let loadCommitContent: (Project, File, String) async throws -> (before: String?, after: String?)
    private let loadWorktreeContent: (Project, File) async throws -> (before: String?, after: String?)
    private let loadCommitDiff: (Project, File, String) async throws -> String
    private let loadWorktreeDiff: (Project, File) async throws -> String
    private let missingProjectError: () -> Error
    private let copyText: (String) -> Void
    private let handleEvent: (FileDetailHostEvent) -> Void
    private let fileChangeToken: Int
    private let commitChangeToken: Int

    @State private var unifiedDiffText = ""
    @State private var diffIssueMessage: String?
    @State private var showTextPreview = false
    @State private var textPreviewTitle = ""
    @State private var textPreviewContent = ""
    @State private var beforeImage: NSImage?
    @State private var afterImage: NSImage?
    @State private var imageDiffMode: GitDetailImageDiffMode = .twoUp
    @State private var imageBlendAmount = GitDetailDiffDisplayRules.defaultImageBlendAmount
    @State private var imageLoadGeneration = 0
    @State private var diffLoadGeneration = 0
    @State private var textPreviewGeneration = 0

    public init(
        project: Project?,
        file: File?,
        selectedCommit: SelectedCommit?,
        filePath: @escaping (File) -> String,
        isImage: @escaping (File) -> Bool,
        isBinary: @escaping (File) -> Bool,
        changeType: @escaping (File) -> String,
        existingPatch: @escaping (File) -> String,
        selectedCommitHash: @escaping (SelectedCommit) -> String,
        loadCurrentCommitData: @escaping (Project, File, String) async throws -> Data,
        loadCurrentWorktreeData: @escaping (Project, File) async throws -> Data,
        loadCommits: @escaping (Project) async throws -> [LoadedCommit],
        loadedCommitHash: @escaping (LoadedCommit) -> String,
        loadedParentHashes: @escaping (LoadedCommit) -> [String],
        loadHeadHash: @escaping (Project) async -> String?,
        loadPreviousCommitData: @escaping (Project, File, String) async throws -> Data,
        loadCommitContent: @escaping (Project, File, String) async throws -> (before: String?, after: String?),
        loadWorktreeContent: @escaping (Project, File) async throws -> (before: String?, after: String?),
        loadCommitDiff: @escaping (Project, File, String) async throws -> String,
        loadWorktreeDiff: @escaping (Project, File) async throws -> String,
        missingProjectError: @escaping () -> Error,
        copyText: @escaping (String) -> Void,
        handleEvent: @escaping (FileDetailHostEvent) -> Void,
        fileChangeToken: Int = 0,
        commitChangeToken: Int = 0
    ) {
        self.project = project
        self.file = file
        self.selectedCommit = selectedCommit
        self.filePath = filePath
        self.isImage = isImage
        self.isBinary = isBinary
        self.changeType = changeType
        self.existingPatch = existingPatch
        self.selectedCommitHash = selectedCommitHash
        self.loadCurrentCommitData = loadCurrentCommitData
        self.loadCurrentWorktreeData = loadCurrentWorktreeData
        self.loadCommits = loadCommits
        self.loadedCommitHash = loadedCommitHash
        self.loadedParentHashes = loadedParentHashes
        self.loadHeadHash = loadHeadHash
        self.loadPreviousCommitData = loadPreviousCommitData
        self.loadCommitContent = loadCommitContent
        self.loadWorktreeContent = loadWorktreeContent
        self.loadCommitDiff = loadCommitDiff
        self.loadWorktreeDiff = loadWorktreeDiff
        self.missingProjectError = missingProjectError
        self.copyText = copyText
        self.handleEvent = handleEvent
        self.fileChangeToken = fileChangeToken
        self.commitChangeToken = commitChangeToken
    }

    public var body: some View {
        VStack(spacing: 0) {
            if let file {
                FileDetailContentView(
                    filePath: filePath(file),
                    isImage: isImage(file),
                    isBinary: isBinary(file),
                    changeType: changeType(file),
                    diffText: unifiedDiffText,
                    issueMessage: diffIssueMessage,
                    beforeImage: beforeImage,
                    afterImage: afterImage,
                    imageDiffMode: $imageDiffMode,
                    imageBlendAmount: $imageBlendAmount,
                    onRefresh: refreshDiff,
                    onCopyRawDiff: {
                        GitDetailDiffDisplayRules.performRawDiffCopy(diffText: unifiedDiffText, copy: copyText)
                    },
                    onShowBeforeText: {
                        presentTextPreview(kind: .before, for: file)
                    },
                    onShowAfterText: {
                        presentTextPreview(kind: .after, for: file)
                    },
                    onCopyReason: {
                        GitDetailDiffDisplayRules.performIssueMessageCopy(diffIssueMessage, copy: copyText)
                    }
                )
            }
        }
        .onChange(of: fileChangeToken) {
            refreshImages()
            GitDetailDiffDisplayRules.performFileDidChange(performRefreshAction: performDiffRefreshAction)
        }
        .onChange(of: commitChangeToken) {
            refreshImages()
            GitDetailDiffDisplayRules.performCommitDidChange(performRefreshAction: performDiffRefreshAction)
        }
        .onAppear {
            refreshImages()
            GitDetailDiffDisplayRules.performFileDetailAppear(performRefreshAction: performDiffRefreshAction)
        }
        .sheet(isPresented: $showTextPreview) {
            TextPreviewSheetView(title: textPreviewTitle, content: textPreviewContent)
        }
        .frame(maxHeight: .infinity)
    }
}

fileprivate enum FileDetailBackgroundLoader {
    struct UnsafeTransfer<Value>: @unchecked Sendable {
        let value: Value
    }

    static func diffTextLoadResult<Project, File, SelectedCommit>(
        file: File?,
        project: Project?,
        selectedCommit: SelectedCommit?,
        isBinary: (File) -> Bool,
        existingPatch: (File) -> String,
        selectedCommitHash: (SelectedCommit) -> String,
        loadCommitDiff: (Project, File, String) async throws -> String,
        loadWorktreeDiff: (Project, File) async throws -> String
    ) async -> GitDetailDiffDisplayRules.DiffTextLoadResult {
        guard let loadedFile = file, let loadedProject = project else {
            return GitDetailDiffDisplayRules.DiffTextLoadResult(
                state: GitDetailDiffDisplayRules.DiffTextState(text: "", issueMessage: nil),
                errorDescription: nil
            )
        }

        do {
            let source = GitDetailDiffDisplayRules.diffSource(
                isBinary: isBinary(loadedFile),
                selectedCommit: selectedCommit,
                existingPatch: existingPatch(loadedFile)
            )

            switch source {
            case .noneForBinary:
                return GitDetailDiffDisplayRules.DiffTextLoadResult(
                    state: GitDetailDiffDisplayRules.diffTextStateForBinary(),
                    errorDescription: nil
                )
            case .commit:
                guard let selectedCommit else {
                    throw GitDetailError.commitNotFound
                }
                let text = try await loadCommitDiff(loadedProject, loadedFile, selectedCommitHash(selectedCommit))
                return GitDetailDiffDisplayRules.DiffTextLoadResult(
                    state: GitDetailDiffDisplayRules.diffTextStateForLoadedText(text),
                    errorDescription: nil
                )
            case let .existingPatch(patch):
                return GitDetailDiffDisplayRules.DiffTextLoadResult(
                    state: GitDetailDiffDisplayRules.diffTextStateForLoadedText(patch),
                    errorDescription: nil
                )
            case .worktree:
                let text = try await loadWorktreeDiff(loadedProject, loadedFile)
                return GitDetailDiffDisplayRules.DiffTextLoadResult(
                    state: GitDetailDiffDisplayRules.diffTextStateForLoadedText(text),
                    errorDescription: nil
                )
            }
        } catch {
            let errorDescription = error.localizedDescription
            return GitDetailDiffDisplayRules.DiffTextLoadResult(
                state: GitDetailDiffDisplayRules.diffTextStateForFailure(errorDescription: errorDescription),
                errorDescription: errorDescription
            )
        }
    }
}

private extension FileDetailHostView {
    enum TextPreviewLoadResult {
        case success(GitDetailDiffDisplayRules.TextPreviewState)
        case failure(GitDetailDiffDisplayRules.TextPreviewFailureState)
    }

    func currentImageData(project: Project?, file: File, selectedCommit: SelectedCommit?) async -> Data? {
        guard let loadedProject = project else { return nil }
        nonisolated(unsafe) let project = loadedProject
        nonisolated(unsafe) let file = file

        do {
            switch GitDetailDiffDisplayRules.fileContentSource(
                selectedCommit: selectedCommit,
                commitHash: selectedCommitHash
            ) {
            case let .commit(hash):
                return try await loadCurrentCommitData(project, file, hash)
            case .worktree:
                return try await loadCurrentWorktreeData(project, file)
            }
        } catch {
            return nil
        }
    }

    func previousImageData(project: Project?, file: File, selectedCommit: SelectedCommit?) async -> Data? {
        guard let loadedProject = project else { return nil }
        nonisolated(unsafe) let project = loadedProject
        nonisolated(unsafe) let file = file

        let commits = (try? await loadCommits(project)) ?? []
        let summaries = GitDetailDiffDisplayRules.commitSummaries(
            from: commits,
            commitHash: loadedCommitHash,
            parentHashes: loadedParentHashes
        )
        let source = GitDetailDiffDisplayRules.previousFileContentSource(
            currentSource: GitDetailDiffDisplayRules.fileContentSource(
                selectedCommit: selectedCommit,
                commitHash: selectedCommitHash
            ),
            commits: summaries,
            headHash: await loadHeadHash(project)
        )

        guard case let .commit(hash) = source else {
            return nil
        }

        return try? await loadPreviousCommitData(project, file, hash)
    }

    func textPreviewLoadResult(
        version: GitDetailDiffDisplayRules.TextVersion,
        path: String,
        project: Project?,
        file: File,
        selectedCommit: SelectedCommit?,
        missingError: Error
    ) async -> TextPreviewLoadResult {
        guard let loadedProject = project else {
            return .failure(GitDetailDiffDisplayRules.textPreviewFailureState(
                for: version,
                errorDescription: missingError.localizedDescription
            ))
        }
        nonisolated(unsafe) let project = loadedProject
        nonisolated(unsafe) let file = file

        do {
            let content: String
            switch GitDetailDiffDisplayRules.fileContentSource(
                selectedCommit: selectedCommit,
                commitHash: selectedCommitHash
            ) {
            case let .commit(hash):
                let contents = try await loadCommitContent(project, file, hash)
                content = try GitDetailDiffDisplayRules.textContent(
                    version: version,
                    before: contents.before,
                    after: contents.after
                )
            case .worktree:
                let contents = try await loadWorktreeContent(project, file)
                content = try GitDetailDiffDisplayRules.textContent(
                    version: version,
                    before: contents.before,
                    after: contents.after
                )
            }

            return .success(GitDetailDiffDisplayRules.textPreviewState(
                version: version,
                path: path,
                content: content
            ))
        } catch {
            return .failure(GitDetailDiffDisplayRules.textPreviewFailureState(
                for: version,
                errorDescription: error.localizedDescription
            ))
        }
    }

    func diffTextLoadResult(
        file: File?,
        project: Project?,
        selectedCommit: SelectedCommit?
    ) async -> GitDetailDiffDisplayRules.DiffTextLoadResult {
        guard let loadedFile = file, let loadedProject = project else {
            return GitDetailDiffDisplayRules.DiffTextLoadResult(
                state: GitDetailDiffDisplayRules.DiffTextState(text: "", issueMessage: nil),
                errorDescription: nil
            )
        }
        nonisolated(unsafe) let project = loadedProject
        nonisolated(unsafe) let file = loadedFile

        do {
            let source = GitDetailDiffDisplayRules.diffSource(
                isBinary: isBinary(file),
                selectedCommit: selectedCommit,
                existingPatch: existingPatch(file)
            )

            switch source {
            case .noneForBinary:
                return GitDetailDiffDisplayRules.DiffTextLoadResult(
                    state: GitDetailDiffDisplayRules.diffTextStateForBinary(),
                    errorDescription: nil
                )
            case .commit:
                guard let selectedCommit else {
                    throw GitDetailError.commitNotFound
                }
                let text = try await loadCommitDiff(project, file, selectedCommitHash(selectedCommit))
                return GitDetailDiffDisplayRules.DiffTextLoadResult(
                    state: GitDetailDiffDisplayRules.diffTextStateForLoadedText(text),
                    errorDescription: nil
                )
            case let .existingPatch(patch):
                return GitDetailDiffDisplayRules.DiffTextLoadResult(
                    state: GitDetailDiffDisplayRules.diffTextStateForLoadedText(patch),
                    errorDescription: nil
                )
            case .worktree:
                let text = try await loadWorktreeDiff(project, file)
                return GitDetailDiffDisplayRules.DiffTextLoadResult(
                    state: GitDetailDiffDisplayRules.diffTextStateForLoadedText(text),
                    errorDescription: nil
                )
            }
        } catch {
            let errorDescription = error.localizedDescription
            return GitDetailDiffDisplayRules.DiffTextLoadResult(
                state: GitDetailDiffDisplayRules.diffTextStateForFailure(errorDescription: errorDescription),
                errorDescription: errorDescription
            )
        }
    }

    func refreshImages() {
        imageLoadGeneration += 1
        let generation = imageLoadGeneration

        guard let file, isImage(file) else {
            beforeImage = nil
            afterImage = nil
            return
        }

        let project = project
        let selectedCommit = selectedCommit

        Task(priority: .userInitiated) { @MainActor in
            let afterData = await currentImageData(
                project: project,
                file: file,
                selectedCommit: selectedCommit
            )

            let beforeData = await previousImageData(
                project: project,
                file: file,
                selectedCommit: selectedCommit
            )

            let (nextBeforeImage, nextAfterImage) = await Task.detached(priority: .userInitiated) {
                (
                    GitDetailImageFactory.image(from: beforeData),
                    GitDetailImageFactory.image(from: afterData)
                )
            }.value

            guard generation == imageLoadGeneration else { return }
            beforeImage = nextBeforeImage
            afterImage = nextAfterImage
        }
    }

    func refreshDiff() {
        GitDetailDiffDisplayRules.performManualRefresh(performRefreshAction: performDiffRefreshAction)
    }

    func performDiffRefreshAction(_ action: GitDetailDiffDisplayRules.DiffRefreshAction) {
        GitDetailDiffDisplayRules.performDiffRefreshAction(action) { reason in
            updateDiffView(reason: reason)
        }
    }

    func presentTextPreview(kind: GitDetailDiffDisplayRules.TextVersion, for file: File) {
        textPreviewGeneration += 1
        let generation = textPreviewGeneration

        let project = project
        let selectedCommit = selectedCommit
        let path = filePath(file)
        let missingError = missingProjectError()

        Task(priority: .userInitiated) { @MainActor in
            let result = await textPreviewLoadResult(
                version: kind,
                path: path,
                project: project,
                file: file,
                selectedCommit: selectedCommit,
                missingError: missingError
            )

            guard generation == textPreviewGeneration else { return }

            switch result {
            case let .success(previewState):
                GitDetailDiffDisplayRules.performTextPreviewState(
                    previewState,
                    setTitle: { textPreviewTitle = $0 },
                    setContent: { textPreviewContent = $0 },
                    setPresented: { showTextPreview = $0 }
                )
            case let .failure(failureState):
                handleEvent(.textPreviewFailure(issueMessage: failureState.issueMessage))
                GitDetailDiffDisplayRules.performTextPreviewFailureState(
                    failureState,
                    setIssueMessage: { diffIssueMessage = $0 },
                    showError: { handleEvent(.error($0)) }
                )
            }
        }
    }

    func applyDiffTextState(_ state: GitDetailDiffDisplayRules.DiffTextState) {
        GitDetailDiffDisplayRules.performDiffTextState(
            state,
            setText: { unifiedDiffText = $0 },
            setIssueMessage: { diffIssueMessage = $0 }
        )
    }

    func updateDiffView(reason: String) {
        handleEvent(.update(reason: reason))

        diffLoadGeneration += 1
        let generation = diffLoadGeneration
        let file = file
        let project = project
        let selectedCommit = selectedCommit
        let fileTransfer = FileDetailBackgroundLoader.UnsafeTransfer(value: file)
        let projectTransfer = FileDetailBackgroundLoader.UnsafeTransfer(value: project)
        let selectedCommitTransfer = FileDetailBackgroundLoader.UnsafeTransfer(value: selectedCommit)
        let isBinaryTransfer = FileDetailBackgroundLoader.UnsafeTransfer(value: isBinary)
        let existingPatchTransfer = FileDetailBackgroundLoader.UnsafeTransfer(value: existingPatch)
        let selectedCommitHashTransfer = FileDetailBackgroundLoader.UnsafeTransfer(value: selectedCommitHash)
        let loadCommitDiffTransfer = FileDetailBackgroundLoader.UnsafeTransfer(value: loadCommitDiff)
        let loadWorktreeDiffTransfer = FileDetailBackgroundLoader.UnsafeTransfer(value: loadWorktreeDiff)
        let handleEventTransfer = FileDetailBackgroundLoader.UnsafeTransfer(value: handleEvent)

        Task.detached(priority: .userInitiated) {
            let result = await FileDetailBackgroundLoader.diffTextLoadResult(
                file: fileTransfer.value,
                project: projectTransfer.value,
                selectedCommit: selectedCommitTransfer.value,
                isBinary: isBinaryTransfer.value,
                existingPatch: existingPatchTransfer.value,
                selectedCommitHash: selectedCommitHashTransfer.value,
                loadCommitDiff: loadCommitDiffTransfer.value,
                loadWorktreeDiff: loadWorktreeDiffTransfer.value
            )

            await MainActor.run {
                guard generation == diffLoadGeneration else { return }

                if let failureDescription = result.errorDescription {
                    handleEventTransfer.value(.diffFailure(errorDescription: failureDescription))
                    handleEventTransfer.value(.error(failureDescription))
                }

                applyDiffTextState(result.state)
            }
        }
    }
}
