import MagicAlert
import MagicDiffView
import MagicKit
import OSLog
import GitOKCoreFeatures
import SwiftUI

struct FileDetail: View, SuperLog {
    @EnvironmentObject var data: DataVM
    @EnvironmentObject var vm: ProjectVM

    @State private var fileChangeToken = 0
    @State private var commitChangeToken = 0

    static let emoji = "🌍"
    private var verbose = false

    var body: some View {
        FileDetailHostView(
            project: vm.project,
            file: vm.file,
            selectedCommit: data.commit,
            filePath: \.file,
            isImage: \.isImage,
            isBinary: \.isBinary,
            changeType: \.changeType,
            existingPatch: \.diff,
            selectedCommitHash: \.hash,
            loadCurrentCommitData: { project, file, hash in
                try project.fileData(at: hash, file: file.file)
            },
            loadCurrentWorktreeData: { project, file in
                try GitDetailDiffDisplayRules.worktreeFileData(
                    projectPath: project.path,
                    filePath: file.file
                )
            },
            loadCommits: { project in
                project.getCommits("Load previous image")
            },
            loadedCommitHash: \.hash,
            loadedParentHashes: \.parentHashes,
            loadHeadHash: { project in
                project.headCommitHash()
            },
            loadPreviousCommitData: { project, file, hash in
                try project.fileData(at: hash, file: file.file)
            },
            loadCommitContent: { project, file, hash in
                try project.fileContentChange(at: hash, file: file.file)
            },
            loadWorktreeContent: { project, file in
                try project.uncommittedFileContentChange(file: file.file)
            },
            loadCommitDiff: { project, file, hash in
                try project.fileDiff(at: hash, file: file.file)
            },
            loadWorktreeDiff: { project, file in
                try project.uncommittedFileDiff(file: file.file)
            },
            missingProjectError: {
                GitDetailError.invalidProject
            },
            copyText: { text in
                GitDetailPasteboard.writeString(text)
            },
            handleEvent: handleEvent,
            fileChangeToken: fileChangeToken,
            commitChangeToken: commitChangeToken
        ) { diffText in
            MagicDiffView(diffOutput: diffText)
                .background(.background)
        }
        .onChange(of: vm.file) {
            fileChangeToken += 1
        }
        .onChange(of: data.commit) {
            commitChangeToken += 1
        }
    }
}

private extension FileDetail {
    func handleEvent(_ event: FileDetailHostEvent) {
        switch event {
        case let .error(message):
            GitDetailAlertRules.performMessage(message) {
                alert_error($0)
            }
        case let .update(reason):
            if verbose {
                os_log("\(self.t)\(GitDetailDiffDisplayRules.updateDiffViewLogMessage(reason: reason))")
            }
        case let .textPreviewFailure(issueMessage):
            os_log(.error, "\(Self.t)\(GitDetailDiffDisplayRules.textPreviewFailureLogMessage(issueMessage: issueMessage))")
        case let .diffFailure(errorDescription):
            os_log(.error, "\(Self.t)❌ \(GitDetailDiffDisplayRules.diffRefreshFailureLogMessage(errorDescription: errorDescription))")
        }
    }
}
