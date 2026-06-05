import AppKit
import SwiftUI

public enum FileDetailHostEvent {
    case error(String)
    case update(reason: String)
    case textPreviewFailure(issueMessage: String)
    case diffFailure(errorDescription: String)
}

public struct FileDetailHostView<Project, File, SelectedCommit>: View {
    private let project: Project?
    private let file: File?
    private let selectedCommit: SelectedCommit?
    private let filePath: (File) -> String
    private let isImage: (File) -> Bool
    private let isBinary: (File) -> Bool
    private let changeType: (File) -> String
    private let existingPatch: (File) -> String
    private let selectedCommitHash: (SelectedCommit) -> String
    private let selectedCommitParentHashes: (SelectedCommit) -> [String]
    private let loadCurrentCommitData: (Project, File, String) async throws -> Data
    private let loadCurrentWorktreeData: (Project, File) async throws -> Data
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
    @State private var imageIssueMessage: String?
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
    @State private var imageLoadTask: Task<Void, Never>?
    @State private var diffLoadTask: Task<Void, Never>?
    @State private var textPreviewTask: Task<Void, Never>?

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
        selectedCommitParentHashes: @escaping (SelectedCommit) -> [String],
        loadCurrentCommitData: @escaping (Project, File, String) async throws -> Data,
        loadCurrentWorktreeData: @escaping (Project, File) async throws -> Data,
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
        self.selectedCommitParentHashes = selectedCommitParentHashes
        self.loadCurrentCommitData = loadCurrentCommitData
        self.loadCurrentWorktreeData = loadCurrentWorktreeData
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
                    issueMessage: isImage(file) ? imageIssueMessage ?? diffIssueMessage : diffIssueMessage,
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
            clearLoadedContent()
            refreshImages()
            GitDetailDiffDisplayRules.performFileDidChange(performRefreshAction: performDiffRefreshAction)
        }
        .onChange(of: commitChangeToken) {
            clearLoadedContent()
            refreshImages()
            GitDetailDiffDisplayRules.performCommitDidChange(performRefreshAction: performDiffRefreshAction)
        }
        .onAppear {
            refreshImages()
            GitDetailDiffDisplayRules.performFileDetailAppear(performRefreshAction: performDiffRefreshAction)
        }
        .onDisappear {
            cancelBackgroundLoads()
            clearLoadedContent()
        }
        .sheet(isPresented: $showTextPreview) {
            TextPreviewSheetView(title: textPreviewTitle, content: textPreviewContent)
        }
        .frame(maxHeight: .infinity)
    }
}

fileprivate enum FileDetailBackgroundLoader {
    struct ImageLoadResult {
        let before: NSImage?
        let after: NSImage?
        let issueMessage: String?
    }

    enum TextPreviewLoadResult {
        case success(GitDetailDiffDisplayRules.TextPreviewState)
        case failure(GitDetailDiffDisplayRules.TextPreviewFailureState)
    }

    struct UnsafeTransfer<Value>: @unchecked Sendable {
        let value: Value
    }

    static func currentImageData<Project, File, SelectedCommit>(
        project: Project?,
        file: File,
        selectedCommit: SelectedCommit?,
        selectedCommitHash: (SelectedCommit) -> String,
        loadCurrentCommitData: (Project, File, String) async throws -> Data,
        loadCurrentWorktreeData: (Project, File) async throws -> Data
    ) async -> Data? {
        guard let loadedProject = project else { return nil }

        do {
            switch GitDetailDiffDisplayRules.fileContentSource(
                selectedCommit: selectedCommit,
                commitHash: selectedCommitHash
            ) {
            case let .commit(hash):
                return try await loadCurrentCommitData(loadedProject, file, hash)
            case .worktree:
                return try await loadCurrentWorktreeData(loadedProject, file)
            }
        } catch {
            return nil
        }
    }

    static func previousImageData<Project, File, SelectedCommit>(
        project: Project?,
        file: File,
        selectedCommit: SelectedCommit?,
        selectedCommitHash: (SelectedCommit) -> String,
        selectedCommitParentHashes: (SelectedCommit) -> [String],
        loadHeadHash: (Project) async -> String?,
        loadPreviousCommitData: (Project, File, String) async throws -> Data
    ) async -> Data? {
        guard let loadedProject = project else { return nil }

        let source = GitDetailDiffDisplayRules.previousFileContentSource(
            currentSource: GitDetailDiffDisplayRules.fileContentSource(
                selectedCommit: selectedCommit,
                commitHash: selectedCommitHash
            ),
            selectedCommitParentHashes: selectedCommit.map(selectedCommitParentHashes) ?? [],
            headHash: await loadHeadHash(loadedProject)
        )

        guard case let .commit(hash) = source else {
            return nil
        }

        return try? await loadPreviousCommitData(loadedProject, file, hash)
    }

    static func images<Project, File, SelectedCommit>(
        project: Project?,
        file: File,
        selectedCommit: SelectedCommit?,
        selectedCommitHash: (SelectedCommit) -> String,
        selectedCommitParentHashes: (SelectedCommit) -> [String],
        loadCurrentCommitData: (Project, File, String) async throws -> Data,
        loadCurrentWorktreeData: (Project, File) async throws -> Data,
        loadHeadHash: (Project) async -> String?,
        loadPreviousCommitData: (Project, File, String) async throws -> Data
    ) async -> ImageLoadResult {
        let afterData = await currentImageData(
            project: project,
            file: file,
            selectedCommit: selectedCommit,
            selectedCommitHash: selectedCommitHash,
            loadCurrentCommitData: loadCurrentCommitData,
            loadCurrentWorktreeData: loadCurrentWorktreeData
        )
        if let issueMessage = imageDataIssueMessage(afterData) {
            return ImageLoadResult(before: nil, after: nil, issueMessage: issueMessage)
        }

        let beforeData = await previousImageData(
            project: project,
            file: file,
            selectedCommit: selectedCommit,
            selectedCommitHash: selectedCommitHash,
            selectedCommitParentHashes: selectedCommitParentHashes,
            loadHeadHash: loadHeadHash,
            loadPreviousCommitData: loadPreviousCommitData
        )
        if let issueMessage = imageDataIssueMessage(beforeData) {
            return ImageLoadResult(before: nil, after: nil, issueMessage: issueMessage)
        }

        return ImageLoadResult(
            before: GitDetailImageFactory.image(from: beforeData),
            after: GitDetailImageFactory.image(from: afterData),
            issueMessage: nil
        )
    }

    static func imageDataIssueMessage(_ data: Data?) -> String? {
        guard let data,
              data.count > GitDetailDiffDisplayRules.maxPreviewImageBytes else {
            return nil
        }

        return GitDetailDiffDisplayRules.imagePreviewTooLargeMessage(byteCount: data.count)
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

    static func textPreviewLoadResult<Project, File, SelectedCommit>(
        version: GitDetailDiffDisplayRules.TextVersion,
        path: String,
        project: Project?,
        file: File,
        selectedCommit: SelectedCommit?,
        missingError: Error,
        selectedCommitHash: (SelectedCommit) -> String,
        loadCommitContent: (Project, File, String) async throws -> (before: String?, after: String?),
        loadWorktreeContent: (Project, File) async throws -> (before: String?, after: String?)
    ) async -> TextPreviewLoadResult {
        guard let loadedProject = project else {
            return .failure(GitDetailDiffDisplayRules.textPreviewFailureState(
                for: version,
                errorDescription: missingError.localizedDescription
            ))
        }

        do {
            let content: String
            switch GitDetailDiffDisplayRules.fileContentSource(
                selectedCommit: selectedCommit,
                commitHash: selectedCommitHash
            ) {
            case let .commit(hash):
                let contents = try await loadCommitContent(loadedProject, file, hash)
                content = try GitDetailDiffDisplayRules.textContent(
                    version: version,
                    before: contents.before,
                    after: contents.after
                )
            case .worktree:
                let contents = try await loadWorktreeContent(loadedProject, file)
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
}

private extension FileDetailHostView {
    func cancelBackgroundLoads() {
        imageLoadGeneration += 1
        diffLoadGeneration += 1
        textPreviewGeneration += 1
        imageLoadTask?.cancel()
        diffLoadTask?.cancel()
        textPreviewTask?.cancel()
        imageLoadTask = nil
        diffLoadTask = nil
        textPreviewTask = nil
    }

    func clearLoadedContent() {
        unifiedDiffText = ""
        diffIssueMessage = nil
        imageIssueMessage = nil
        beforeImage = nil
        afterImage = nil
        showTextPreview = false
        textPreviewTitle = ""
        textPreviewContent = ""
    }

    func refreshImages() {
        imageLoadGeneration += 1
        let generation = imageLoadGeneration
        imageLoadTask?.cancel()
        imageLoadTask = nil

        guard let file, isImage(file) else {
            beforeImage = nil
            afterImage = nil
            imageIssueMessage = nil
            return
        }

        let project = project
        let selectedCommit = selectedCommit
        let projectTransfer = FileDetailBackgroundLoader.UnsafeTransfer(value: project)
        let fileTransfer = FileDetailBackgroundLoader.UnsafeTransfer(value: file)
        let selectedCommitTransfer = FileDetailBackgroundLoader.UnsafeTransfer(value: selectedCommit)
        let selectedCommitHashTransfer = FileDetailBackgroundLoader.UnsafeTransfer(value: selectedCommitHash)
        let selectedCommitParentHashesTransfer = FileDetailBackgroundLoader.UnsafeTransfer(value: selectedCommitParentHashes)
        let loadCurrentCommitDataTransfer = FileDetailBackgroundLoader.UnsafeTransfer(value: loadCurrentCommitData)
        let loadCurrentWorktreeDataTransfer = FileDetailBackgroundLoader.UnsafeTransfer(value: loadCurrentWorktreeData)
        let loadHeadHashTransfer = FileDetailBackgroundLoader.UnsafeTransfer(value: loadHeadHash)
        let loadPreviousCommitDataTransfer = FileDetailBackgroundLoader.UnsafeTransfer(value: loadPreviousCommitData)

        imageLoadTask = Task.detached(priority: .userInitiated) {
            let images = await FileDetailBackgroundLoader.images(
                project: projectTransfer.value,
                file: fileTransfer.value,
                selectedCommit: selectedCommitTransfer.value,
                selectedCommitHash: selectedCommitHashTransfer.value,
                selectedCommitParentHashes: selectedCommitParentHashesTransfer.value,
                loadCurrentCommitData: loadCurrentCommitDataTransfer.value,
                loadCurrentWorktreeData: loadCurrentWorktreeDataTransfer.value,
                loadHeadHash: loadHeadHashTransfer.value,
                loadPreviousCommitData: loadPreviousCommitDataTransfer.value
            )

            guard Task.isCancelled == false else { return }
            await MainActor.run {
                guard generation == imageLoadGeneration else { return }
                beforeImage = images.before
                afterImage = images.after
                imageIssueMessage = images.issueMessage
                imageLoadTask = nil
            }
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
        textPreviewTask?.cancel()
        textPreviewTask = nil

        let project = project
        let selectedCommit = selectedCommit
        let path = filePath(file)
        let missingError = missingProjectError()
        let kindTransfer = FileDetailBackgroundLoader.UnsafeTransfer(value: kind)
        let projectTransfer = FileDetailBackgroundLoader.UnsafeTransfer(value: project)
        let fileTransfer = FileDetailBackgroundLoader.UnsafeTransfer(value: file)
        let selectedCommitTransfer = FileDetailBackgroundLoader.UnsafeTransfer(value: selectedCommit)
        let missingErrorTransfer = FileDetailBackgroundLoader.UnsafeTransfer(value: missingError)
        let selectedCommitHashTransfer = FileDetailBackgroundLoader.UnsafeTransfer(value: selectedCommitHash)
        let loadCommitContentTransfer = FileDetailBackgroundLoader.UnsafeTransfer(value: loadCommitContent)
        let loadWorktreeContentTransfer = FileDetailBackgroundLoader.UnsafeTransfer(value: loadWorktreeContent)
        let handleEventTransfer = FileDetailBackgroundLoader.UnsafeTransfer(value: handleEvent)

        textPreviewTask = Task.detached(priority: .userInitiated) {
            let result = await FileDetailBackgroundLoader.textPreviewLoadResult(
                version: kindTransfer.value,
                path: path,
                project: projectTransfer.value,
                file: fileTransfer.value,
                selectedCommit: selectedCommitTransfer.value,
                missingError: missingErrorTransfer.value,
                selectedCommitHash: selectedCommitHashTransfer.value,
                loadCommitContent: loadCommitContentTransfer.value,
                loadWorktreeContent: loadWorktreeContentTransfer.value
            )

            guard Task.isCancelled == false else { return }
            await MainActor.run {
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
                    handleEventTransfer.value(.textPreviewFailure(issueMessage: failureState.issueMessage))
                    GitDetailDiffDisplayRules.performTextPreviewFailureState(
                        failureState,
                        setIssueMessage: { diffIssueMessage = $0 },
                        showError: { handleEventTransfer.value(.error($0)) }
                    )
                }
                textPreviewTask = nil
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
        diffLoadTask?.cancel()
        diffLoadTask = nil
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

        diffLoadTask = Task.detached(priority: .userInitiated) {
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

            guard Task.isCancelled == false else { return }
            await MainActor.run {
                guard generation == diffLoadGeneration else { return }

                if let failureDescription = result.errorDescription {
                    handleEventTransfer.value(.diffFailure(errorDescription: failureDescription))
                    handleEventTransfer.value(.error(failureDescription))
                }

                applyDiffTextState(result.state)
                diffLoadTask = nil
            }
        }
    }
}
