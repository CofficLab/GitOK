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
    private let loadCurrentCommitData: (Project, File, String) throws -> Data
    private let loadCurrentWorktreeData: (Project, File) throws -> Data
    private let loadCommits: (Project) throws -> [LoadedCommit]
    private let loadedCommitHash: (LoadedCommit) -> String
    private let loadedParentHashes: (LoadedCommit) -> [String]
    private let loadHeadHash: (Project) -> String?
    private let loadPreviousCommitData: (Project, File, String) throws -> Data
    private let loadCommitContent: (Project, File, String) throws -> (before: String?, after: String?)
    private let loadWorktreeContent: (Project, File) throws -> (before: String?, after: String?)
    private let loadCommitDiff: (Project, File, String) throws -> String
    private let loadWorktreeDiff: (Project, File) throws -> String
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
        loadCurrentCommitData: @escaping (Project, File, String) throws -> Data,
        loadCurrentWorktreeData: @escaping (Project, File) throws -> Data,
        loadCommits: @escaping (Project) throws -> [LoadedCommit],
        loadedCommitHash: @escaping (LoadedCommit) -> String,
        loadedParentHashes: @escaping (LoadedCommit) -> [String],
        loadHeadHash: @escaping (Project) -> String?,
        loadPreviousCommitData: @escaping (Project, File, String) throws -> Data,
        loadCommitContent: @escaping (Project, File, String) throws -> (before: String?, after: String?),
        loadWorktreeContent: @escaping (Project, File) throws -> (before: String?, after: String?),
        loadCommitDiff: @escaping (Project, File, String) throws -> String,
        loadWorktreeDiff: @escaping (Project, File) throws -> String,
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

private extension FileDetailHostView {
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

        DispatchQueue.global(qos: .userInitiated).async {
            let nextAfterImage = GitDetailImageFactory.image(from: GitDetailDiffDisplayRules.optionalProjectCurrentImageData(
                project: project,
                selectedCommit: selectedCommit,
                commitHash: selectedCommitHash,
                loadCommitData: { project, hash in
                    try loadCurrentCommitData(project, file, hash)
                },
                loadWorktreeData: { project in
                    try loadCurrentWorktreeData(project, file)
                }
            ))

            let nextBeforeImage = GitDetailImageFactory.image(from: GitDetailDiffDisplayRules.optionalProjectPreviousImageData(
                project: project,
                selectedCommit: selectedCommit,
                commitHash: selectedCommitHash,
                loadCommits: loadCommits,
                loadedCommitHash: loadedCommitHash,
                loadedParentHashes: loadedParentHashes,
                loadHeadHash: loadHeadHash,
                loadCommitData: { project, hash in
                    try loadPreviousCommitData(project, file, hash)
                }
            ))

            DispatchQueue.main.async {
                guard generation == imageLoadGeneration else { return }
                beforeImage = nextBeforeImage
                afterImage = nextAfterImage
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

        let project = project
        let selectedCommit = selectedCommit
        let path = filePath(file)
        let missingError = missingProjectError()

        DispatchQueue.global(qos: .userInitiated).async {
            var previewState: GitDetailDiffDisplayRules.TextPreviewState?
            var failureState: GitDetailDiffDisplayRules.TextPreviewFailureState?

            GitDetailDiffDisplayRules.performProjectTextPreviewLoad(
                version: kind,
                path: path,
                project: project,
                missingError: missingError,
                selectedCommit: selectedCommit,
                commitHash: selectedCommitHash,
                loadCommitContent: { project, hash in
                    try loadCommitContent(project, file, hash)
                },
                loadWorktreeContent: { project in
                    try loadWorktreeContent(project, file)
                },
                applyPreview: { state in
                    previewState = state
                },
                applyFailure: { state in
                    failureState = state
                }
            )

            DispatchQueue.main.async {
                guard generation == textPreviewGeneration else { return }

                if let previewState {
                    GitDetailDiffDisplayRules.performTextPreviewState(
                        previewState,
                        setTitle: { textPreviewTitle = $0 },
                        setContent: { textPreviewContent = $0 },
                        setPresented: { showTextPreview = $0 }
                    )
                }

                if let failureState {
                    handleEvent(.textPreviewFailure(issueMessage: failureState.issueMessage))
                    GitDetailDiffDisplayRules.performTextPreviewFailureState(
                        failureState,
                        setIssueMessage: { diffIssueMessage = $0 },
                        showError: { handleEvent(.error($0)) }
                    )
                }
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

        DispatchQueue.global(qos: .userInitiated).async {
            var nextState: GitDetailDiffDisplayRules.DiffTextState?
            var failureDescription: String?

            GitDetailDiffDisplayRules.performRequiredDiffTextRefresh(
                file: file,
                project: project,
                selectedCommit: selectedCommit,
                isBinary: isBinary,
                existingPatch: existingPatch,
                commitHash: selectedCommitHash,
                loadCommitDiff: loadCommitDiff,
                loadWorktreeDiff: loadWorktreeDiff,
                applyDiffTextState: { nextState = $0 },
                handleFailure: { failureDescription = $0 }
            )

            DispatchQueue.main.async {
                guard generation == diffLoadGeneration else { return }

                if let failureDescription {
                    handleEvent(.diffFailure(errorDescription: failureDescription))
                    handleEvent(.error(failureDescription))
                }

                if let nextState {
                    applyDiffTextState(nextState)
                }
            }
        }
    }
}
