import AppKit
import SwiftUI

public enum FileDetailHostEvent {
    case error(String)
    case update(reason: String)
    case textPreviewFailure(issueMessage: String)
    case diffFailure(errorDescription: String)
}

public struct FileDetailHostView<Project, File, SelectedCommit, LoadedCommit, RenderContent: View>: View {
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
    private let renderContent: (String) -> RenderContent

    @State private var unifiedDiffText = ""
    @State private var diffIssueMessage: String?
    @State private var showTextPreview = false
    @State private var textPreviewTitle = ""
    @State private var textPreviewContent = ""
    @State private var imageDiffMode: GitDetailImageDiffMode = .twoUp
    @State private var imageBlendAmount = GitDetailDiffDisplayRules.defaultImageBlendAmount

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
        commitChangeToken: Int = 0,
        @ViewBuilder renderContent: @escaping (String) -> RenderContent
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
        self.renderContent = renderContent
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
                    beforeImage: loadImageBefore(file: file),
                    afterImage: loadImageFromCommit(file: file),
                    imageDiffMode: $imageDiffMode,
                    imageBlendAmount: $imageBlendAmount,
                    renderContent: {
                        renderContent(unifiedDiffText)
                    },
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
            GitDetailDiffDisplayRules.performFileDidChange(performRefreshAction: performDiffRefreshAction)
        }
        .onChange(of: commitChangeToken) {
            GitDetailDiffDisplayRules.performCommitDidChange(performRefreshAction: performDiffRefreshAction)
        }
        .onAppear {
            GitDetailDiffDisplayRules.performFileDetailAppear(performRefreshAction: performDiffRefreshAction)
        }
        .sheet(isPresented: $showTextPreview) {
            TextPreviewSheetView(title: textPreviewTitle, content: textPreviewContent)
        }
        .frame(maxHeight: .infinity)
    }
}

private extension FileDetailHostView {
    func loadImageFromCommit(file: File) -> NSImage? {
        GitDetailImageFactory.image(from: GitDetailDiffDisplayRules.optionalProjectCurrentImageData(
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
    }

    func loadImageBefore(file: File) -> NSImage? {
        GitDetailImageFactory.image(from: GitDetailDiffDisplayRules.optionalProjectPreviousImageData(
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
        Task(priority: .userInitiated) { @MainActor in
            GitDetailDiffDisplayRules.performProjectTextPreviewLoad(
                version: kind,
                path: filePath(file),
                project: project,
                missingError: missingProjectError(),
                selectedCommit: selectedCommit,
                commitHash: selectedCommitHash,
                loadCommitContent: { project, hash in
                    try loadCommitContent(project, file, hash)
                },
                loadWorktreeContent: { project in
                    try loadWorktreeContent(project, file)
                },
                applyPreview: { previewState in
                    GitDetailDiffDisplayRules.performTextPreviewState(
                        previewState,
                        setTitle: { textPreviewTitle = $0 },
                        setContent: { textPreviewContent = $0 },
                        setPresented: { showTextPreview = $0 }
                    )
                },
                applyFailure: { failureState in
                    handleEvent(.textPreviewFailure(issueMessage: failureState.issueMessage))
                    GitDetailDiffDisplayRules.performTextPreviewFailureState(
                        failureState,
                        setIssueMessage: { diffIssueMessage = $0 },
                        showError: { handleEvent(.error($0)) }
                    )
                }
            )
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

        GitDetailDiffDisplayRules.performRequiredDiffTextRefresh(
            file: file,
            project: project,
            selectedCommit: selectedCommit,
            isBinary: isBinary,
            existingPatch: existingPatch,
            commitHash: selectedCommitHash,
            loadCommitDiff: loadCommitDiff,
            loadWorktreeDiff: loadWorktreeDiff,
            applyDiffTextState: applyDiffTextState,
            handleFailure: { errorDescription in
                handleEvent(.diffFailure(errorDescription: errorDescription))
                handleEvent(.error(errorDescription))
            }
        )
    }
}
