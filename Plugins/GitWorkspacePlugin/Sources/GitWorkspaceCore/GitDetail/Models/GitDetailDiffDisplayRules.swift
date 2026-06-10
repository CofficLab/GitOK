import Foundation

public enum GitDetailDiffDisplayRules {
    public enum TextVersion {
        case before
        case after
    }

    public enum ImageDisplayMode: Equatable, Sendable {
        case new
        case deleted
        case comparison
    }

    public enum DiffSource: Equatable, Sendable {
        case noneForBinary
        case commit
        case existingPatch(String)
        case worktree
    }

    public enum FileContentSource: Equatable, Sendable {
        case commit(hash: String)
        case worktree
    }

    public enum PreviousFileContentSource: Equatable, Sendable {
        case commit(hash: String)
        case unavailable
    }

    public enum DiffContentMode: Equatable, Sendable {
        case empty
        case large
        case render
    }

    public enum DiffRefreshAction: Equatable, Sendable {
        case refresh(reason: String)
    }

    public struct TextPreviewState: Equatable, Sendable {
        public let title: String
        public let content: String
        public let isPresented: Bool

        public init(title: String, content: String, isPresented: Bool) {
            self.title = title
            self.content = content
            self.isPresented = isPresented
        }
    }

    public struct TextPreviewFailureState: Equatable, Sendable {
        public let issueMessage: String
        public let alertMessage: String

        public init(issueMessage: String, alertMessage: String) {
            self.issueMessage = issueMessage
            self.alertMessage = alertMessage
        }
    }

    public struct DiffTextState: Equatable, Sendable {
        public let text: String
        public let issueMessage: String?

        public init(text: String, issueMessage: String?) {
            self.text = text
            self.issueMessage = issueMessage
        }
    }

    public struct DiffTextLoadResult: Equatable, Sendable {
        public let state: DiffTextState
        public let errorDescription: String?

        public init(state: DiffTextState, errorDescription: String?) {
            self.state = state
            self.errorDescription = errorDescription
        }
    }

    public struct ProjectDiffTextRefreshRequest<Project, File> {
        public let project: Project
        public let file: File

        public init(project: Project, file: File) {
            self.project = project
            self.file = file
        }
    }

    public struct ProjectCurrentImageDataRequest<Project, File> {
        public let project: Project
        public let file: File
        public let source: FileContentSource

        public init(project: Project, file: File, source: FileContentSource) {
            self.project = project
            self.file = file
            self.source = source
        }
    }

    public struct ProjectCurrentImageDataHandlers<Project, File> {
        public let loadCommitData: (Project, File, String) throws -> Data
        public let loadWorktreeData: (Project, File) throws -> Data

        public init(
            loadCommitData: @escaping (Project, File, String) throws -> Data,
            loadWorktreeData: @escaping (Project, File) throws -> Data
        ) {
            self.loadCommitData = loadCommitData
            self.loadWorktreeData = loadWorktreeData
        }
    }

    public struct ProjectPreviousImageDataRequest<Project, File> {
        public let project: Project
        public let file: File
        public let commitHash: String

        public init(project: Project, file: File, commitHash: String) {
            self.project = project
            self.file = file
            self.commitHash = commitHash
        }
    }

    public struct ProjectPreviousImageDataHandlers<Project, File, LoadedCommit> {
        public let loadCommits: (Project) throws -> [LoadedCommit]
        public let loadedCommitHash: (LoadedCommit) -> String
        public let loadedParentHashes: (LoadedCommit) -> [String]
        public let loadHeadHash: (Project) -> String?
        public let loadCommitData: (Project, File, String) throws -> Data

        public init(
            loadCommits: @escaping (Project) throws -> [LoadedCommit],
            loadedCommitHash: @escaping (LoadedCommit) -> String,
            loadedParentHashes: @escaping (LoadedCommit) -> [String],
            loadHeadHash: @escaping (Project) -> String?,
            loadCommitData: @escaping (Project, File, String) throws -> Data
        ) {
            self.loadCommits = loadCommits
            self.loadedCommitHash = loadedCommitHash
            self.loadedParentHashes = loadedParentHashes
            self.loadHeadHash = loadHeadHash
            self.loadCommitData = loadCommitData
        }
    }

    public struct ProjectTextPreviewLoadRequest<Project, File> {
        public let project: Project
        public let file: File
        public let source: FileContentSource

        public init(project: Project, file: File, source: FileContentSource) {
            self.project = project
            self.file = file
            self.source = source
        }
    }

    public struct ProjectTextPreviewLoadHandlers<Project, File> {
        public let loadCommitContent: (Project, File, String) throws -> (before: String?, after: String?)
        public let loadWorktreeContent: (Project, File) throws -> (before: String?, after: String?)

        public init(
            loadCommitContent: @escaping (Project, File, String) throws -> (before: String?, after: String?),
            loadWorktreeContent: @escaping (Project, File) throws -> (before: String?, after: String?)
        ) {
            self.loadCommitContent = loadCommitContent
            self.loadWorktreeContent = loadWorktreeContent
        }
    }

    public struct FileDetailPresentationState: Equatable, Sendable {
        public let fileIcon: String
        public let diffContentMode: DiffContentMode
        public let imageDisplayMode: ImageDisplayMode
        public let canShowBeforeText: Bool
        public let canShowAfterText: Bool

        public init(
            fileIcon: String,
            diffContentMode: DiffContentMode,
            imageDisplayMode: ImageDisplayMode,
            canShowBeforeText: Bool,
            canShowAfterText: Bool
        ) {
            self.fileIcon = fileIcon
            self.diffContentMode = diffContentMode
            self.imageDisplayMode = imageDisplayMode
            self.canShowBeforeText = canShowBeforeText
            self.canShowAfterText = canShowAfterText
        }
    }

    public static let maxRenderableDiffCharacters = 500_000
    public static let maxRenderableDiffFiles = 200
    public static let maxPreviewImageBytes = 20 * 1024 * 1024
    public static let defaultImageBlendAmount = 0.5
    public static let defaultFileIcon = "doc.text"
    public static let manualRefreshReason = "Manual Refresh"
    public static let fileChangeRefreshReason = "File Change"
    public static let commitChangeRefreshReason = "Commit Change"
    public static let appearRefreshReason = "Appear"

    public static func shouldSkipDiffRendering(characterCount: Int, maxRenderableCharacters: Int = maxRenderableDiffCharacters) -> Bool {
        characterCount > maxRenderableCharacters
    }

    public static func diffFileCount(in diffText: String, stopAfter: Int? = nil) -> Int {
        var count = 0
        diffText.enumerateLines { line, stop in
            if line.hasPrefix("diff --git ") || line.hasPrefix("diff --cc ") || line.hasPrefix("diff --combined ") {
                count += 1
                if let stopAfter, count > stopAfter {
                    stop = true
                }
            }
        }
        return count
    }

    public static func shouldSkipDiffRendering(
        diffText: String,
        maxRenderableCharacters: Int = maxRenderableDiffCharacters,
        maxRenderableFiles: Int = maxRenderableDiffFiles
    ) -> Bool {
        shouldSkipDiffRendering(characterCount: diffText.count, maxRenderableCharacters: maxRenderableCharacters)
            || diffFileCount(in: diffText, stopAfter: maxRenderableFiles) > maxRenderableFiles
    }

    public static func diffContentMode(diffText: String) -> DiffContentMode {
        if diffText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .empty
        }

        if shouldSkipDiffRendering(diffText: diffText) {
            return .large
        }

        return .render
    }

    public static func fileIcon(isImage: Bool, isBinary: Bool) -> String {
        if isImage { return "photo" }
        if isBinary { return "doc.badge.gearshape" }
        return "doc.text"
    }

    public static func imageDisplayMode(changeType: String) -> ImageDisplayMode {
        switch changeType.uppercased() {
        case "A", "?":
            return .new
        case "D":
            return .deleted
        default:
            return .comparison
        }
    }

    public static func fileDetailPresentationState(
        isImage: Bool,
        isBinary: Bool,
        changeType: String,
        diffText: String
    ) -> FileDetailPresentationState {
        FileDetailPresentationState(
            fileIcon: fileIcon(isImage: isImage, isBinary: isBinary),
            diffContentMode: diffContentMode(diffText: diffText),
            imageDisplayMode: imageDisplayMode(changeType: changeType),
            canShowBeforeText: hasBeforeText(changeType: changeType),
            canShowAfterText: hasAfterText(changeType: changeType)
        )
    }

    public static func performRawDiffCopy(
        diffText: String,
        copy: (String) -> Void
    ) {
        copy(diffText)
    }

    public static func imagePreviewTitle(for mode: ImageDisplayMode) -> String {
        switch mode {
        case .new:
            return GitDetailLocalization.string("New Image")
        case .deleted:
            return GitDetailLocalization.string("Deleted Image")
        case .comparison:
            return GitDetailLocalization.string("Image Comparison")
        }
    }

    public static func diffSource(isBinary: Bool, hasSelectedCommit: Bool, existingPatch: String) -> DiffSource {
        if isBinary {
            return .noneForBinary
        }

        if hasSelectedCommit {
            return .commit
        }

        if existingPatch.isEmpty == false {
            return .existingPatch(existingPatch)
        }

        return .worktree
    }

    public static func diffSource<Commit>(
        isBinary: Bool,
        selectedCommit: Commit?,
        existingPatch: String
    ) -> DiffSource {
        diffSource(
            isBinary: isBinary,
            hasSelectedCommit: selectedCommit != nil,
            existingPatch: existingPatch
        )
    }

    public static func diffTextStateForBinary() -> DiffTextState {
        DiffTextState(text: "", issueMessage: nil)
    }

    public static func diffTextStateForLoadedText(_ text: String) -> DiffTextState {
        DiffTextState(text: text, issueMessage: nil)
    }

    public static func diffTextStateForFailure(errorDescription: String) -> DiffTextState {
        DiffTextState(text: "", issueMessage: errorDescription)
    }

    public static func imagePreviewTooLargeMessage(byteCount: Int, maxBytes: Int = maxPreviewImageBytes) -> String {
        let sizeMB = max(1, Int(ceil(Double(byteCount) / 1024.0 / 1024.0)))
        let maxMB = max(1, maxBytes / 1024 / 1024)
        return GitDetailLocalization.string("Image preview skipped because the file is \(sizeMB) MB, exceeding the \(maxMB) MB preview limit.")
    }

    public static func diffTextLoadResult(
        source: DiffSource,
        loadCommitDiff: () throws -> String,
        loadWorktreeDiff: () throws -> String
    ) -> DiffTextLoadResult {
        do {
            switch source {
            case .noneForBinary:
                return DiffTextLoadResult(state: diffTextStateForBinary(), errorDescription: nil)
            case .commit:
                return DiffTextLoadResult(
                    state: diffTextStateForLoadedText(try loadCommitDiff()),
                    errorDescription: nil
                )
            case let .existingPatch(patch):
                return DiffTextLoadResult(state: diffTextStateForLoadedText(patch), errorDescription: nil)
            case .worktree:
                return DiffTextLoadResult(
                    state: diffTextStateForLoadedText(try loadWorktreeDiff()),
                    errorDescription: nil
                )
            }
        } catch {
            let errorDescription = error.localizedDescription
            return DiffTextLoadResult(
                state: diffTextStateForFailure(errorDescription: errorDescription),
                errorDescription: errorDescription
            )
        }
    }

    public static func diffTextLoadResult(
        source: DiffSource,
        selectedCommitHash: String?,
        loadCommitDiff: (String) throws -> String,
        loadWorktreeDiff: () throws -> String
    ) -> DiffTextLoadResult {
        diffTextLoadResult(
            source: source,
            loadCommitDiff: {
                guard let selectedCommitHash else {
                    throw GitDetailError.commitNotFound
                }

                return try loadCommitDiff(selectedCommitHash)
            },
            loadWorktreeDiff: loadWorktreeDiff
        )
    }

    public static func diffTextLoadResult<Commit>(
        source: DiffSource,
        selectedCommit: Commit?,
        commitHash: (Commit) -> String,
        loadCommitDiff: (String) throws -> String,
        loadWorktreeDiff: () throws -> String
    ) -> DiffTextLoadResult {
        diffTextLoadResult(
            source: source,
            selectedCommitHash: selectedCommit.map(commitHash),
            loadCommitDiff: loadCommitDiff,
            loadWorktreeDiff: loadWorktreeDiff
        )
    }

    public static func fileContentSource(selectedCommitHash: String?) -> FileContentSource {
        if let selectedCommitHash {
            return .commit(hash: selectedCommitHash)
        }

        return .worktree
    }

    public static func fileContentSource<Commit>(
        selectedCommit: Commit?,
        commitHash: (Commit) -> String
    ) -> FileContentSource {
        fileContentSource(selectedCommitHash: selectedCommit.map(commitHash))
    }

    public static func textContent(
        version: TextVersion,
        source: FileContentSource,
        loadCommitContent: (String) throws -> (before: String?, after: String?),
        loadWorktreeContent: () throws -> (before: String?, after: String?)
    ) throws -> String {
        let contents: (before: String?, after: String?)
        switch source {
        case let .commit(hash):
            contents = try loadCommitContent(hash)
        case .worktree:
            contents = try loadWorktreeContent()
        }

        return try textContent(
            version: version,
            before: contents.before,
            after: contents.after
        )
    }

    public static func textContent<Commit>(
        version: TextVersion,
        selectedCommit: Commit?,
        commitHash: (Commit) -> String,
        loadCommitContent: (String) throws -> (before: String?, after: String?),
        loadWorktreeContent: () throws -> (before: String?, after: String?)
    ) throws -> String {
        try textContent(
            version: version,
            source: fileContentSource(selectedCommit: selectedCommit, commitHash: commitHash),
            loadCommitContent: loadCommitContent,
            loadWorktreeContent: loadWorktreeContent
        )
    }

    public static func projectTextContent<Project, Commit>(
        version: TextVersion,
        project: Project?,
        missingError: @autoclosure () -> Error,
        selectedCommit: Commit?,
        commitHash: (Commit) -> String,
        loadCommitContent: (Project, String) throws -> (before: String?, after: String?),
        loadWorktreeContent: (Project) throws -> (before: String?, after: String?)
    ) throws -> String {
        try requiredProjectValue(
            project,
            missingError: missingError()
        ) { project in
            try textContent(
                version: version,
                selectedCommit: selectedCommit,
                commitHash: commitHash,
                loadCommitContent: { hash in
                    try loadCommitContent(project, hash)
                },
                loadWorktreeContent: {
                    try loadWorktreeContent(project)
                }
            )
        }
    }

    public static func imageData(
        source: FileContentSource,
        loadCommitData: (String) throws -> Data,
        loadWorktreeData: () throws -> Data
    ) throws -> Data {
        switch source {
        case let .commit(hash):
            return try loadCommitData(hash)
        case .worktree:
            return try loadWorktreeData()
        }
    }

    public static func optionalImageData(
        source: FileContentSource,
        loadCommitData: (String) throws -> Data,
        loadWorktreeData: () throws -> Data
    ) -> Data? {
        try? imageData(
            source: source,
            loadCommitData: loadCommitData,
            loadWorktreeData: loadWorktreeData
        )
    }

    public static func worktreeFileURL(projectPath: String, filePath: String) -> URL {
        URL(fileURLWithPath: projectPath)
            .appendingPathComponent(filePath)
    }

    public static func worktreeFileData(
        projectPath: String,
        filePath: String,
        loadData: (URL) throws -> Data = { try Data(contentsOf: $0) }
    ) throws -> Data {
        try loadData(worktreeFileURL(projectPath: projectPath, filePath: filePath))
    }

    public static func imageData(
        source: PreviousFileContentSource,
        loadCommitData: (String) throws -> Data
    ) throws -> Data? {
        switch source {
        case let .commit(hash):
            return try loadCommitData(hash)
        case .unavailable:
            return nil
        }
    }

    public static func optionalImageData(
        source: PreviousFileContentSource,
        loadCommitData: (String) throws -> Data
    ) -> Data? {
        try? imageData(
            source: source,
            loadCommitData: loadCommitData
        )
    }

    public static func optionalCurrentImageData<Commit>(
        selectedCommit: Commit?,
        commitHash: (Commit) -> String,
        loadCommitData: (String) throws -> Data,
        loadWorktreeData: () throws -> Data
    ) -> Data? {
        optionalImageData(
            source: fileContentSource(selectedCommit: selectedCommit, commitHash: commitHash),
            loadCommitData: loadCommitData,
            loadWorktreeData: loadWorktreeData
        )
    }

    public static func optionalProjectCurrentImageData<Project, Commit>(
        project: Project?,
        selectedCommit: Commit?,
        commitHash: (Commit) -> String,
        loadCommitData: (Project, String) throws -> Data,
        loadWorktreeData: (Project) throws -> Data
    ) -> Data? {
        optionalRequiredProjectValue(project) { project in
            optionalCurrentImageData(
                selectedCommit: selectedCommit,
                commitHash: commitHash,
                loadCommitData: { hash in
                    try loadCommitData(project, hash)
                },
                loadWorktreeData: {
                    try loadWorktreeData(project)
                }
            )
        }
    }

    public static func optionalProjectCurrentImageDataCommand<Project, Commit, File>(
        project: Project?,
        file: File,
        selectedCommit: Commit?,
        commitHash: (Commit) -> String,
        loadData: (ProjectCurrentImageDataRequest<Project, File>) throws -> Data
    ) -> Data? {
        optionalRequiredProjectValue(project) { project in
            try? loadData(ProjectCurrentImageDataRequest(
                project: project,
                file: file,
                source: fileContentSource(selectedCommit: selectedCommit, commitHash: commitHash)
            ))
        }
    }

    public static func optionalProjectCurrentImageDataCommand<Project, Commit, File>(
        project: Project?,
        file: File,
        selectedCommit: Commit?,
        commitHash: (Commit) -> String,
        handlers: ProjectCurrentImageDataHandlers<Project, File>
    ) -> Data? {
        optionalProjectCurrentImageDataCommand(
            project: project,
            file: file,
            selectedCommit: selectedCommit,
            commitHash: commitHash,
            loadData: { request in
                switch request.source {
                case let .commit(hash):
                    return try handlers.loadCommitData(request.project, request.file, hash)
                case .worktree:
                    return try handlers.loadWorktreeData(request.project, request.file)
                }
            }
        )
    }

    public static func optionalPreviousImageData<SelectedCommit, LoadedCommit>(
        selectedCommit: SelectedCommit?,
        commitHash: (SelectedCommit) -> String,
        loadCommits: () throws -> [LoadedCommit],
        loadedCommitHash: (LoadedCommit) -> String,
        loadedParentHashes: (LoadedCommit) -> [String],
        loadHeadHash: () -> String?,
        loadCommitData: (String) throws -> Data
    ) -> Data? {
        optionalImageData(
            source: safePreviousFileContentSource(
                selectedCommit: selectedCommit,
                commitHash: commitHash,
                loadCommits: loadCommits,
                loadedCommitHash: loadedCommitHash,
                loadedParentHashes: loadedParentHashes,
                loadHeadHash: loadHeadHash
            ),
            loadCommitData: loadCommitData
        )
    }

    public static func optionalProjectPreviousImageData<Project, SelectedCommit, LoadedCommit>(
        project: Project?,
        selectedCommit: SelectedCommit?,
        commitHash: (SelectedCommit) -> String,
        loadCommits: (Project) throws -> [LoadedCommit],
        loadedCommitHash: (LoadedCommit) -> String,
        loadedParentHashes: (LoadedCommit) -> [String],
        loadHeadHash: (Project) -> String?,
        loadCommitData: (Project, String) throws -> Data
    ) -> Data? {
        optionalRequiredProjectValue(project) { project in
            optionalPreviousImageData(
                selectedCommit: selectedCommit,
                commitHash: commitHash,
                loadCommits: {
                    try loadCommits(project)
                },
                loadedCommitHash: loadedCommitHash,
                loadedParentHashes: loadedParentHashes,
                loadHeadHash: {
                    loadHeadHash(project)
                },
                loadCommitData: { hash in
                    try loadCommitData(project, hash)
                }
            )
        }
    }

    public static func optionalProjectPreviousImageDataCommand<Project, SelectedCommit, LoadedCommit, File>(
        project: Project?,
        file: File,
        selectedCommit: SelectedCommit?,
        commitHash: (SelectedCommit) -> String,
        loadCommits: (Project) throws -> [LoadedCommit],
        loadedCommitHash: (LoadedCommit) -> String,
        loadedParentHashes: (LoadedCommit) -> [String],
        loadHeadHash: (Project) -> String?,
        loadData: (ProjectPreviousImageDataRequest<Project, File>) throws -> Data
    ) -> Data? {
        optionalRequiredProjectValue(project) { project in
            let source = safePreviousFileContentSource(
                selectedCommit: selectedCommit,
                commitHash: commitHash,
                loadCommits: {
                    try loadCommits(project)
                },
                loadedCommitHash: loadedCommitHash,
                loadedParentHashes: loadedParentHashes,
                loadHeadHash: {
                    loadHeadHash(project)
                }
            )

            guard case let .commit(hash) = source else {
                return nil
            }

            return try? loadData(ProjectPreviousImageDataRequest(
                project: project,
                file: file,
                commitHash: hash
            ))
        }
    }

    public static func optionalProjectPreviousImageDataCommand<Project, SelectedCommit, LoadedCommit, File>(
        project: Project?,
        file: File,
        selectedCommit: SelectedCommit?,
        commitHash: (SelectedCommit) -> String,
        handlers: ProjectPreviousImageDataHandlers<Project, File, LoadedCommit>
    ) -> Data? {
        optionalProjectPreviousImageDataCommand(
            project: project,
            file: file,
            selectedCommit: selectedCommit,
            commitHash: commitHash,
            loadCommits: handlers.loadCommits,
            loadedCommitHash: handlers.loadedCommitHash,
            loadedParentHashes: handlers.loadedParentHashes,
            loadHeadHash: handlers.loadHeadHash,
            loadData: { request in
                try handlers.loadCommitData(request.project, request.file, request.commitHash)
            }
        )
    }

    public static func optionalRequiredProjectValue<Project, Value>(
        _ project: Project?,
        perform: (Project) -> Value?
    ) -> Value? {
        guard let project else {
            return nil
        }

        return perform(project)
    }

    public static func requiredProjectValue<Project, Value>(
        _ project: Project?,
        missingError: @autoclosure () -> Error,
        perform: (Project) throws -> Value
    ) throws -> Value {
        guard let project else {
            throw missingError()
        }

        return try perform(project)
    }

    public static func parentHash(
        selectedCommitHash: String,
        commits: [(hash: String, parentHashes: [String])]
    ) -> String? {
        commits.first { $0.hash == selectedCommitHash }?.parentHashes.first
    }

    public static func previousFileContentSource(
        selectedCommitHash: String?,
        commits: [(hash: String, parentHashes: [String])],
        headHash: String?
    ) -> PreviousFileContentSource {
        if let selectedCommitHash {
            guard let parentHash = parentHash(selectedCommitHash: selectedCommitHash, commits: commits) else {
                return .unavailable
            }
            return .commit(hash: parentHash)
        }

        guard let headHash else {
            return .unavailable
        }
        return .commit(hash: headHash)
    }

    public static func previousFileContentSource(
        currentSource: FileContentSource,
        selectedCommitParentHashes: [String],
        headHash: String?
    ) -> PreviousFileContentSource {
        switch currentSource {
        case .commit:
            guard let parentHash = selectedCommitParentHashes.first else {
                return .unavailable
            }
            return .commit(hash: parentHash)
        case .worktree:
            return previousFileContentSource(
                selectedCommitHash: nil,
                commits: [],
                headHash: headHash
            )
        }
    }

    public static func previousFileContentSource(
        currentSource: FileContentSource,
        loadCommits: () -> [(hash: String, parentHashes: [String])],
        loadHeadHash: () -> String?
    ) -> PreviousFileContentSource {
        switch currentSource {
        case let .commit(hash):
            return previousFileContentSource(
                selectedCommitHash: hash,
                commits: loadCommits(),
                headHash: nil
            )
        case .worktree:
            return previousFileContentSource(
                selectedCommitHash: nil,
                commits: [],
                headHash: loadHeadHash()
            )
        }
    }

    public static func safePreviousFileContentSource(
        currentSource: FileContentSource,
        loadCommits: () throws -> [(hash: String, parentHashes: [String])],
        loadHeadHash: () -> String?
    ) -> PreviousFileContentSource {
        previousFileContentSource(
            currentSource: currentSource,
            loadCommits: { (try? loadCommits()) ?? [] },
            loadHeadHash: loadHeadHash
        )
    }

    public static func previousFileContentSource<Commit>(
        selectedCommit: Commit?,
        commitHash: (Commit) -> String,
        loadCommits: () -> [(hash: String, parentHashes: [String])],
        loadHeadHash: () -> String?
    ) -> PreviousFileContentSource {
        previousFileContentSource(
            currentSource: fileContentSource(selectedCommit: selectedCommit, commitHash: commitHash),
            loadCommits: loadCommits,
            loadHeadHash: loadHeadHash
        )
    }

    public static func safePreviousFileContentSource<Commit>(
        selectedCommit: Commit?,
        commitHash: (Commit) -> String,
        loadCommits: () throws -> [(hash: String, parentHashes: [String])],
        loadHeadHash: () -> String?
    ) -> PreviousFileContentSource {
        safePreviousFileContentSource(
            currentSource: fileContentSource(selectedCommit: selectedCommit, commitHash: commitHash),
            loadCommits: loadCommits,
            loadHeadHash: loadHeadHash
        )
    }

    public static func commitSummaries<Commit>(
        from commits: [Commit],
        commitHash: (Commit) -> String,
        parentHashes: (Commit) -> [String]
    ) -> [(hash: String, parentHashes: [String])] {
        commits.map {
            (hash: commitHash($0), parentHashes: parentHashes($0))
        }
    }

    public static func safePreviousFileContentSource<SelectedCommit, LoadedCommit>(
        selectedCommit: SelectedCommit?,
        commitHash: (SelectedCommit) -> String,
        loadCommits: () throws -> [LoadedCommit],
        loadedCommitHash: (LoadedCommit) -> String,
        loadedParentHashes: (LoadedCommit) -> [String],
        loadHeadHash: () -> String?
    ) -> PreviousFileContentSource {
        safePreviousFileContentSource(
            selectedCommit: selectedCommit,
            commitHash: commitHash,
            loadCommits: {
                commitSummaries(
                    from: try loadCommits(),
                    commitHash: loadedCommitHash,
                    parentHashes: loadedParentHashes
                )
            },
            loadHeadHash: loadHeadHash
        )
    }

    public static func emptyDiffExplanation(changeType: String, issueMessage: String?) -> String {
        if let issueMessage, issueMessage.isEmpty == false {
            return GitDetailLocalization.string("Diff data could not be generated. You can check whether the file still exists, verify it is text-encoded, or refresh the current view.")
        }

        switch changeType.uppercased() {
        case "A", "?":
            return GitDetailLocalization.string("No parseable text diff was generated for this new file. Common causes include an empty file, non-text content, or Git not returning a patch. You can still view the new text directly.")
        case "D":
            return GitDetailLocalization.string("No displayable patch was retrieved for this deleted file. Common causes include an empty file or Git not returning a deletion diff. You can still view the text before deletion.")
        default:
            return GitDetailLocalization.string("No text differences to display for this file. It may be unchanged, empty, or the diff output is empty. You can view the original and new text directly to confirm.")
        }
    }

    @discardableResult
    public static func performIssueMessageCopy(
        _ issueMessage: String?,
        copy: (String) -> Void
    ) -> Bool {
        guard let issueMessage, issueMessage.isEmpty == false else {
            return false
        }

        copy(issueMessage)
        return true
    }

    public static func changeTypeLabel(_ changeType: String) -> String {
        switch changeType.uppercased() {
        case "A": return GitDetailLocalization.string("Staged New")
        case "?": return GitDetailLocalization.string("Untracked New")
        case "M": return GitDetailLocalization.string("Modified")
        case "D": return GitDetailLocalization.string("Deleted")
        case "R": return GitDetailLocalization.string("Renamed")
        case "C": return GitDetailLocalization.string("Copied")
        case "T": return GitDetailLocalization.string("Type Changed")
        default: return changeType
        }
    }

    public static func hasBeforeText(changeType: String) -> Bool {
        switch changeType.uppercased() {
        case "A", "?":
            return false
        default:
            return true
        }
    }

    public static func hasAfterText(changeType: String) -> Bool {
        switch changeType.uppercased() {
        case "D":
            return false
        default:
            return true
        }
    }

    public static func textPreviewBaseTitle(for version: TextVersion) -> String {
        switch version {
        case .before:
            return GitDetailLocalization.string("Original Text")
        case .after:
            return GitDetailLocalization.string("New Text")
        }
    }

    public static func textPreviewTitle(for version: TextVersion, path: String) -> String {
        "\(textPreviewBaseTitle(for: version)) · \(path)"
    }

    public static func textPreviewState(
        version: TextVersion,
        path: String,
        content: String
    ) -> TextPreviewState {
        TextPreviewState(
            title: textPreviewTitle(for: version, path: path),
            content: content,
            isPresented: true
        )
    }

    public static func performTextPreviewState(
        _ state: TextPreviewState,
        setTitle: (String) -> Void,
        setContent: (String) -> Void,
        setPresented: (Bool) -> Void
    ) {
        setTitle(state.title)
        setContent(state.content)
        setPresented(state.isPresented)
    }

    public static func refreshActionOnManualRefresh() -> DiffRefreshAction {
        .refresh(reason: manualRefreshReason)
    }

    public static func refreshActionOnFileChanged() -> DiffRefreshAction {
        .refresh(reason: fileChangeRefreshReason)
    }

    public static func refreshActionOnCommitChanged() -> DiffRefreshAction {
        .refresh(reason: commitChangeRefreshReason)
    }

    public static func refreshActionOnAppear() -> DiffRefreshAction {
        .refresh(reason: appearRefreshReason)
    }

    public static func performManualRefresh(
        performRefreshAction: (DiffRefreshAction) -> Void
    ) {
        performRefreshAction(refreshActionOnManualRefresh())
    }

    public static func performFileDidChange(
        performRefreshAction: (DiffRefreshAction) -> Void
    ) {
        performRefreshAction(refreshActionOnFileChanged())
    }

    public static func performCommitDidChange(
        performRefreshAction: (DiffRefreshAction) -> Void
    ) {
        performRefreshAction(refreshActionOnCommitChanged())
    }

    public static func performFileDetailAppear(
        performRefreshAction: (DiffRefreshAction) -> Void
    ) {
        performRefreshAction(refreshActionOnAppear())
    }

    public static func performDiffRefreshAction(
        _ action: DiffRefreshAction,
        refresh: (String) -> Void
    ) {
        switch action {
        case let .refresh(reason):
            refresh(reason)
        }
    }

    public static func performDiffTextState(
        _ state: DiffTextState,
        setText: (String) -> Void,
        setIssueMessage: (String?) -> Void
    ) {
        setText(state.text)
        setIssueMessage(state.issueMessage)
    }

    @discardableResult
    public static func performRequiredFileAndProject<File, Project>(
        file: File?,
        project: Project?,
        perform: (File, Project) -> Void
    ) -> Bool {
        guard let file, let project else {
            return false
        }

        perform(file, project)
        return true
    }

    public static func performDiffTextRefreshOperation<Commit>(
        isBinary: Bool,
        selectedCommit: Commit?,
        existingPatch: String,
        commitHash: (Commit) -> String,
        loadCommitDiff: (String) throws -> String,
        loadWorktreeDiff: () throws -> String,
        applyDiffTextState: (DiffTextState) -> Void,
        handleFailure: (String) -> Void
    ) {
        let source = diffSource(
            isBinary: isBinary,
            selectedCommit: selectedCommit,
            existingPatch: existingPatch
        )
        let result = diffTextLoadResult(
            source: source,
            selectedCommit: selectedCommit,
            commitHash: commitHash,
            loadCommitDiff: loadCommitDiff,
            loadWorktreeDiff: loadWorktreeDiff
        )

        if let errorDescription = result.errorDescription {
            handleFailure(errorDescription)
        }

        applyDiffTextState(result.state)
    }

    @discardableResult
    public static func performRequiredDiffTextRefresh<File, Project, Commit>(
        file: File?,
        project: Project?,
        selectedCommit: Commit?,
        isBinary: (File) -> Bool,
        existingPatch: (File) -> String,
        commitHash: (Commit) -> String,
        loadCommitDiff: (Project, File, String) throws -> String,
        loadWorktreeDiff: (Project, File) throws -> String,
        applyDiffTextState: (DiffTextState) -> Void,
        handleFailure: (String) -> Void
    ) -> Bool {
        performRequiredFileAndProject(file: file, project: project) { file, project in
            performDiffTextRefreshOperation(
                isBinary: isBinary(file),
                selectedCommit: selectedCommit,
                existingPatch: existingPatch(file),
                commitHash: commitHash,
                loadCommitDiff: { hash in
                    try loadCommitDiff(project, file, hash)
                },
                loadWorktreeDiff: {
                    try loadWorktreeDiff(project, file)
                },
                applyDiffTextState: applyDiffTextState,
                handleFailure: handleFailure
            )
        }
    }

    @discardableResult
    public static func performRequiredDiffTextRefreshCommand<File, Project, Commit>(
        file: File?,
        project: Project?,
        selectedCommit: Commit?,
        isBinary: (File) -> Bool,
        existingPatch: (File) -> String,
        commitHash: (Commit) -> String,
        loadCommitDiff: (ProjectDiffTextRefreshRequest<Project, File>, String) throws -> String,
        loadWorktreeDiff: (ProjectDiffTextRefreshRequest<Project, File>) throws -> String,
        applyDiffTextState: (DiffTextState) -> Void,
        handleFailure: (String) -> Void
    ) -> Bool {
        performRequiredFileAndProject(file: file, project: project) { file, project in
            let request = ProjectDiffTextRefreshRequest(project: project, file: file)
            performDiffTextRefreshOperation(
                isBinary: isBinary(file),
                selectedCommit: selectedCommit,
                existingPatch: existingPatch(file),
                commitHash: commitHash,
                loadCommitDiff: { hash in
                    try loadCommitDiff(request, hash)
                },
                loadWorktreeDiff: {
                    try loadWorktreeDiff(request)
                },
                applyDiffTextState: applyDiffTextState,
                handleFailure: handleFailure
            )
        }
    }

    public static func diffRefreshFailureLogMessage(errorDescription: String) -> String {
        "更新差异视图失败: \(errorDescription)"
    }

    public static func textPreviewFailureLogMessage(issueMessage: String) -> String {
        "❌ \(issueMessage)"
    }

    public static func updateDiffViewLogMessage(reason: String) -> String {
        "🍋 UpdateDiffView(\(reason))"
    }

    public static func textPreviewLoadErrorMessage(for version: TextVersion, errorDescription: String) -> String {
        let versionLabel = version == .before ? "original" : "new"
        return GitDetailLocalization.string("Unable to load \(versionLabel) text: \(errorDescription)")
    }

    public static func textPreviewFailureState(
        for version: TextVersion,
        errorDescription: String
    ) -> TextPreviewFailureState {
        let message = textPreviewLoadErrorMessage(for: version, errorDescription: errorDescription)
        return TextPreviewFailureState(issueMessage: message, alertMessage: message)
    }

    public static func performTextPreviewFailureState(
        _ state: TextPreviewFailureState,
        setIssueMessage: (String) -> Void,
        showError: (String) -> Void
    ) {
        setIssueMessage(state.issueMessage)
        showError(state.alertMessage)
    }

    public static func performTextPreviewLoad(
        version: TextVersion,
        path: String,
        loadContent: () throws -> String,
        applyPreview: (TextPreviewState) -> Void,
        applyFailure: (TextPreviewFailureState) -> Void
    ) {
        do {
            applyPreview(textPreviewState(
                version: version,
                path: path,
                content: try loadContent()
            ))
        } catch {
            applyFailure(textPreviewFailureState(
                for: version,
                errorDescription: error.localizedDescription
            ))
        }
    }

    public static func performProjectTextPreviewLoad<Project, Commit>(
        version: TextVersion,
        path: String,
        project: Project?,
        missingError: @autoclosure () -> Error,
        selectedCommit: Commit?,
        commitHash: (Commit) -> String,
        loadCommitContent: (Project, String) throws -> (before: String?, after: String?),
        loadWorktreeContent: (Project) throws -> (before: String?, after: String?),
        applyPreview: (TextPreviewState) -> Void,
        applyFailure: (TextPreviewFailureState) -> Void
    ) {
        performTextPreviewLoad(
            version: version,
            path: path,
            loadContent: {
                try projectTextContent(
                    version: version,
                    project: project,
                    missingError: missingError(),
                    selectedCommit: selectedCommit,
                    commitHash: commitHash,
                    loadCommitContent: loadCommitContent,
                    loadWorktreeContent: loadWorktreeContent
                )
            },
            applyPreview: applyPreview,
            applyFailure: applyFailure
        )
    }

    public static func performProjectTextPreviewLoadCommand<Project, Commit, File>(
        version: TextVersion,
        path: String,
        project: Project?,
        missingError: @autoclosure () -> Error,
        file: File,
        selectedCommit: Commit?,
        commitHash: (Commit) -> String,
        loadContent: (ProjectTextPreviewLoadRequest<Project, File>) throws -> (before: String?, after: String?),
        applyPreview: (TextPreviewState) -> Void,
        applyFailure: (TextPreviewFailureState) -> Void
    ) {
        performTextPreviewLoad(
            version: version,
            path: path,
            loadContent: {
                try requiredProjectValue(
                    project,
                    missingError: missingError()
                ) { project in
                    try textContent(
                        version: version,
                        source: fileContentSource(selectedCommit: selectedCommit, commitHash: commitHash),
                        loadCommitContent: { hash in
                            try loadContent(ProjectTextPreviewLoadRequest(
                                project: project,
                                file: file,
                                source: .commit(hash: hash)
                            ))
                        },
                        loadWorktreeContent: {
                            try loadContent(ProjectTextPreviewLoadRequest(
                                project: project,
                                file: file,
                                source: .worktree
                            ))
                        }
                    )
                }
            },
            applyPreview: applyPreview,
            applyFailure: applyFailure
        )
    }

    public static func performProjectTextPreviewLoadCommand<Project, Commit, File>(
        version: TextVersion,
        path: String,
        project: Project?,
        missingError: @autoclosure () -> Error,
        file: File,
        selectedCommit: Commit?,
        commitHash: (Commit) -> String,
        handlers: ProjectTextPreviewLoadHandlers<Project, File>,
        applyPreview: (TextPreviewState) -> Void,
        applyFailure: (TextPreviewFailureState) -> Void
    ) {
        performProjectTextPreviewLoadCommand(
            version: version,
            path: path,
            project: project,
            missingError: missingError(),
            file: file,
            selectedCommit: selectedCommit,
            commitHash: commitHash,
            loadContent: { request in
                switch request.source {
                case let .commit(hash):
                    return try handlers.loadCommitContent(request.project, request.file, hash)
                case .worktree:
                    return try handlers.loadWorktreeContent(request.project, request.file)
                }
            },
            applyPreview: applyPreview,
            applyFailure: applyFailure
        )
    }

    public static func missingTextDescription(for version: TextVersion) -> String {
        switch version {
        case .before:
            return "original text does not exist"
        case .after:
            return "new text does not exist"
        }
    }

    public static func textContentOrEmptyPlaceholder(_ content: String) -> String {
        content.isEmpty ? GitDetailLocalization.string("/* Empty file */") : content
    }

    public static func textContent(
        version: TextVersion,
        before: String?,
        after: String?
    ) throws -> String {
        switch version {
        case .before:
            guard let before else {
                throw GitDetailError.fileNotFound(missingTextDescription(for: version))
            }
            return textContentOrEmptyPlaceholder(before)
        case .after:
            guard let after else {
                throw GitDetailError.fileNotFound(missingTextDescription(for: version))
            }
            return textContentOrEmptyPlaceholder(after)
        }
    }
}
