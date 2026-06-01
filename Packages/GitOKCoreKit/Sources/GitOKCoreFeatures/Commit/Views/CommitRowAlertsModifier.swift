import SwiftUI

public extension View {
    func commitRowAlerts(
        showUndoConfirmation: Binding<Bool>,
        showRevertConfirmation: Binding<Bool>,
        showResetSoftConfirmation: Binding<Bool>,
        showResetMixedConfirmation: Binding<Bool>,
        showResetHardConfirmation: Binding<Bool>,
        showSquashConfirmation: Binding<Bool>,
        squashMessage: Binding<String>,
        showCreateTagAlert: Binding<Bool>,
        newTagName: Binding<String>,
        showCreateAnnotatedTagAlert: Binding<Bool>,
        newAnnotatedTagName: Binding<String>,
        newAnnotatedTagMessage: Binding<String>,
        showDeleteTagConfirmation: Binding<Bool>,
        showDeleteRemoteTagConfirmation: Binding<Bool>,
        isRunningHistoryOperation: Bool,
        isCreatingTag: Bool,
        isCreatingAnnotatedTag: Bool,
        isDeletingTag: Bool,
        isDeletingRemoteTag: Bool,
        commitHash: String,
        commitIndex: Int,
        tag: String,
        onUndo: @escaping () -> Void,
        onRevert: @escaping () -> Void,
        onReset: @escaping (GitResetMode) -> Void,
        onSquash: @escaping () -> Void,
        onCreateLightweightTag: @escaping () -> Void,
        onCreateAnnotatedTag: @escaping () -> Void,
        onDeleteLocalTag: @escaping () -> Void,
        onDeleteRemoteTag: @escaping () -> Void
    ) -> some View {
        modifier(CommitRowAlertsModifier(
            showUndoConfirmation: showUndoConfirmation,
            showRevertConfirmation: showRevertConfirmation,
            showResetSoftConfirmation: showResetSoftConfirmation,
            showResetMixedConfirmation: showResetMixedConfirmation,
            showResetHardConfirmation: showResetHardConfirmation,
            showSquashConfirmation: showSquashConfirmation,
            squashMessage: squashMessage,
            showCreateTagAlert: showCreateTagAlert,
            newTagName: newTagName,
            showCreateAnnotatedTagAlert: showCreateAnnotatedTagAlert,
            newAnnotatedTagName: newAnnotatedTagName,
            newAnnotatedTagMessage: newAnnotatedTagMessage,
            showDeleteTagConfirmation: showDeleteTagConfirmation,
            showDeleteRemoteTagConfirmation: showDeleteRemoteTagConfirmation,
            isRunningHistoryOperation: isRunningHistoryOperation,
            isCreatingTag: isCreatingTag,
            isCreatingAnnotatedTag: isCreatingAnnotatedTag,
            isDeletingTag: isDeletingTag,
            isDeletingRemoteTag: isDeletingRemoteTag,
            commitHash: commitHash,
            commitIndex: commitIndex,
            tag: tag,
            onUndo: onUndo,
            onRevert: onRevert,
            onReset: onReset,
            onSquash: onSquash,
            onCreateLightweightTag: onCreateLightweightTag,
            onCreateAnnotatedTag: onCreateAnnotatedTag,
            onDeleteLocalTag: onDeleteLocalTag,
            onDeleteRemoteTag: onDeleteRemoteTag
        ))
    }
}

private struct CommitRowAlertsModifier: ViewModifier {
    @Binding var showUndoConfirmation: Bool
    @Binding var showRevertConfirmation: Bool
    @Binding var showResetSoftConfirmation: Bool
    @Binding var showResetMixedConfirmation: Bool
    @Binding var showResetHardConfirmation: Bool
    @Binding var showSquashConfirmation: Bool
    @Binding var squashMessage: String
    @Binding var showCreateTagAlert: Bool
    @Binding var newTagName: String
    @Binding var showCreateAnnotatedTagAlert: Bool
    @Binding var newAnnotatedTagName: String
    @Binding var newAnnotatedTagMessage: String
    @Binding var showDeleteTagConfirmation: Bool
    @Binding var showDeleteRemoteTagConfirmation: Bool

    let isRunningHistoryOperation: Bool
    let isCreatingTag: Bool
    let isCreatingAnnotatedTag: Bool
    let isDeletingTag: Bool
    let isDeletingRemoteTag: Bool
    let commitHash: String
    let commitIndex: Int
    let tag: String
    let onUndo: () -> Void
    let onRevert: () -> Void
    let onReset: (GitResetMode) -> Void
    let onSquash: () -> Void
    let onCreateLightweightTag: () -> Void
    let onCreateAnnotatedTag: () -> Void
    let onDeleteLocalTag: () -> Void
    let onDeleteRemoteTag: () -> Void

    func body(content: Content) -> some View {
        content
            .alert(String(localized: "Confirm Undo Commit?", table: "GitCommit"), isPresented: $showUndoConfirmation) {
                Button(String(localized: "Cancel", table: "GitCommit"), role: .cancel) {}
                Button(String(localized: "Undo", table: "GitCommit"), role: .destructive, action: onUndo)
            } message: {
                Text(String(localized: "After undoing, the file changes from this commit will be kept in the working directory for re-editing and committing.", table: "GitCommit"))
            }
            .alert(String(localized: "Confirm Revert This Commit?", table: "GitCommit"), isPresented: $showRevertConfirmation) {
                Button(String(localized: "Cancel", table: "GitCommit"), role: .cancel) {}
                Button("Revert", action: onRevert)
                    .disabled(isRunningHistoryOperation)
            } message: {
                Text(String(localized: "GitOK will create a new reverse commit to undo the changes. Suitable for pushed commits. If there are conflicts, resolve them manually before continuing.", table: "GitCommit"))
            }
            .alert(String(localized: "Confirm Soft Reset?", table: "GitCommit"), isPresented: $showResetSoftConfirmation) {
                Button(String(localized: "Cancel", table: "GitCommit"), role: .cancel) {}
                Button("Soft Reset") {
                    onReset(.soft)
                }
                .disabled(isRunningHistoryOperation)
            } message: {
                Text(String(localized: "HEAD will move to this commit. Changes from subsequent commits will be preserved in the staging area.", table: "GitCommit"))
            }
            .alert(String(localized: "Confirm Mixed Reset?", table: "GitCommit"), isPresented: $showResetMixedConfirmation) {
                Button(String(localized: "Cancel", table: "GitCommit"), role: .cancel) {}
                Button("Mixed Reset") {
                    onReset(.mixed)
                }
                .disabled(isRunningHistoryOperation)
            } message: {
                Text(String(localized: "HEAD will move to this commit. Changes from subsequent commits will be preserved in the working directory but unstaged.", table: "GitCommit"))
            }
            .alert(String(localized: "Confirm Hard Reset?", table: "GitCommit"), isPresented: $showResetHardConfirmation) {
                Button(String(localized: "Cancel", table: "GitCommit"), role: .cancel) {}
                Button("Hard Reset", role: .destructive) {
                    onReset(.hard)
                }
                .disabled(isRunningHistoryOperation)
            } message: {
                Text(String(localized: "HEAD, staging area, and working directory will all revert to this commit. Local commits and uncommitted changes after this commit will be discarded.", table: "GitCommit"))
            }
            .alert(String(localized: "Confirm Squash Commits?", table: "GitCommit"), isPresented: $showSquashConfirmation) {
                TextField(String(localized: "Squash commit message", table: "GitCommit"), text: $squashMessage)
                Button(String(localized: "Cancel", table: "GitCommit"), role: .cancel) {}
                Button("Squash", action: onSquash)
                    .disabled(squashMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isRunningHistoryOperation)
            } message: {
                Text(String(localized: "This will combine \(commitIndex + 1) commits from HEAD to this commit into one. Only recommended for unpushed commits.", table: "GitCommit"))
            }
            .alert(String(localized: "Create Tag", table: "GitCommit"), isPresented: $showCreateTagAlert) {
                TextField(String(localized: "Tag Name", table: "GitCommit"), text: $newTagName)
                Button(String(localized: "Cancel", table: "GitCommit"), role: .cancel) {
                    newTagName = ""
                }
                Button(String(localized: "Create", table: "GitCommit"), action: onCreateLightweightTag)
                    .disabled(CommitTagRules.canCreateLightweightTag(name: newTagName) == false || isCreatingTag)
            } message: {
                Text(String.localizedStringWithFormat(
                    String(localized: "Create a lightweight tag for commit %@.", table: "GitCommit"),
                    CommitTagRules.shortHash(commitHash)
                ))
            }
            .alert(String(localized: "Create Annotated Tag", table: "GitCommit"), isPresented: $showCreateAnnotatedTagAlert) {
                TextField(String(localized: "Tag Name", table: "GitCommit"), text: $newAnnotatedTagName)
                TextField(String(localized: "Tag Message", table: "GitCommit"), text: $newAnnotatedTagMessage)
                Button(String(localized: "Cancel", table: "GitCommit"), role: .cancel) {
                    newAnnotatedTagName = ""
                    newAnnotatedTagMessage = ""
                }
                Button(String(localized: "Create", table: "GitCommit"), action: onCreateAnnotatedTag)
                    .disabled(
                        CommitTagRules.canCreateAnnotatedTag(
                            name: newAnnotatedTagName,
                            message: newAnnotatedTagMessage
                        ) == false ||
                            isCreatingAnnotatedTag
                    )
            } message: {
                Text(String.localizedStringWithFormat(
                    String(localized: "Create an annotated tag for commit %@.", table: "GitCommit"),
                    CommitTagRules.shortHash(commitHash)
                ))
            }
            .alert(String(localized: "Confirm Delete Tag?", table: "GitCommit"), isPresented: $showDeleteTagConfirmation) {
                Button(String(localized: "Cancel", table: "GitCommit"), role: .cancel) {}
                Button(String(localized: "Delete", table: "GitCommit"), role: .destructive, action: onDeleteLocalTag)
                    .disabled(isDeletingTag)
            } message: {
                Text(String.localizedStringWithFormat(
                    String(localized: "This will delete the local tag %@. Remote tags will not be affected.", table: "GitCommit"),
                    tag
                ))
            }
            .alert(String(localized: "Confirm Delete Remote Tag?", table: "GitCommit"), isPresented: $showDeleteRemoteTagConfirmation) {
                Button(String(localized: "Cancel", table: "GitCommit"), role: .cancel) {}
                Button(String(localized: "Delete", table: "GitCommit"), role: .destructive, action: onDeleteRemoteTag)
                    .disabled(isDeletingRemoteTag)
            } message: {
                Text(String.localizedStringWithFormat(
                    String(localized: "This will delete the tag %@ on origin. Local tags will not be affected.", table: "GitCommit"),
                    tag
                ))
            }
    }
}
