import GitCoreKit
import GitOKCoreKit
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
            .alert(CommitLocalization.string("Confirm Undo Commit?"), isPresented: $showUndoConfirmation) {
                Button(CommitLocalization.string("Cancel"), role: .cancel) {}
                Button(CommitLocalization.string("Undo"), role: .destructive, action: onUndo)
            } message: {
                Text(CommitLocalization.string("After undoing, the file changes from this commit will be kept in the working directory for re-editing and committing."))
            }
            .alert(CommitLocalization.string("Confirm Revert This Commit?"), isPresented: $showRevertConfirmation) {
                Button(CommitLocalization.string("Cancel"), role: .cancel) {}
                Button("Revert", action: onRevert)
                    .disabled(isRunningHistoryOperation)
            } message: {
                Text(CommitLocalization.string("GitOK will create a new reverse commit to undo the changes. Suitable for pushed commits. If there are conflicts, resolve them manually before continuing."))
            }
            .alert(CommitLocalization.string("Confirm Soft Reset?"), isPresented: $showResetSoftConfirmation) {
                Button(CommitLocalization.string("Cancel"), role: .cancel) {}
                Button("Soft Reset") {
                    onReset(.soft)
                }
                .disabled(isRunningHistoryOperation)
            } message: {
                Text(CommitLocalization.string("HEAD will move to this commit. Changes from subsequent commits will be preserved in the staging area."))
            }
            .alert(CommitLocalization.string("Confirm Mixed Reset?"), isPresented: $showResetMixedConfirmation) {
                Button(CommitLocalization.string("Cancel"), role: .cancel) {}
                Button("Mixed Reset") {
                    onReset(.mixed)
                }
                .disabled(isRunningHistoryOperation)
            } message: {
                Text(CommitLocalization.string("HEAD will move to this commit. Changes from subsequent commits will be preserved in the working directory but unstaged."))
            }
            .alert(CommitLocalization.string("Confirm Hard Reset?"), isPresented: $showResetHardConfirmation) {
                Button(CommitLocalization.string("Cancel"), role: .cancel) {}
                Button("Hard Reset", role: .destructive) {
                    onReset(.hard)
                }
                .disabled(isRunningHistoryOperation)
            } message: {
                Text(CommitLocalization.string("HEAD, staging area, and working directory will all revert to this commit. Local commits and uncommitted changes after this commit will be discarded."))
            }
            .alert(CommitLocalization.string("Confirm Squash Commits?"), isPresented: $showSquashConfirmation) {
                TextField(CommitLocalization.string("Squash commit message"), text: $squashMessage)
                Button(CommitLocalization.string("Cancel"), role: .cancel) {}
                Button("Squash", action: onSquash)
                    .disabled(squashMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isRunningHistoryOperation)
            } message: {
                Text(CommitLocalization.string("This will combine \(commitIndex + 1) commits from HEAD to this commit into one. Only recommended for unpushed commits."))
            }
            .alert(CommitLocalization.string("Create Tag"), isPresented: $showCreateTagAlert) {
                TextField(CommitLocalization.string("Tag Name"), text: $newTagName)
                Button(CommitLocalization.string("Cancel"), role: .cancel) {
                    newTagName = ""
                }
                Button(CommitLocalization.string("Create"), action: onCreateLightweightTag)
                    .disabled(CommitTagRules.canCreateLightweightTag(name: newTagName) == false || isCreatingTag)
            } message: {
                Text(String.localizedStringWithFormat(
                    CommitLocalization.string("Create a lightweight tag for commit %@."),
                    CommitTagRules.shortHash(commitHash)
                ))
            }
            .alert(CommitLocalization.string("Create Annotated Tag"), isPresented: $showCreateAnnotatedTagAlert) {
                TextField(CommitLocalization.string("Tag Name"), text: $newAnnotatedTagName)
                TextField(CommitLocalization.string("Tag Message"), text: $newAnnotatedTagMessage)
                Button(CommitLocalization.string("Cancel"), role: .cancel) {
                    newAnnotatedTagName = ""
                    newAnnotatedTagMessage = ""
                }
                Button(CommitLocalization.string("Create"), action: onCreateAnnotatedTag)
                    .disabled(
                        CommitTagRules.canCreateAnnotatedTag(
                            name: newAnnotatedTagName,
                            message: newAnnotatedTagMessage
                        ) == false ||
                            isCreatingAnnotatedTag
                    )
            } message: {
                Text(String.localizedStringWithFormat(
                    CommitLocalization.string("Create an annotated tag for commit %@."),
                    CommitTagRules.shortHash(commitHash)
                ))
            }
            .alert(CommitLocalization.string("Confirm Delete Tag?"), isPresented: $showDeleteTagConfirmation) {
                Button(CommitLocalization.string("Cancel"), role: .cancel) {}
                Button(CommitLocalization.string("Delete"), role: .destructive, action: onDeleteLocalTag)
                    .disabled(isDeletingTag)
            } message: {
                Text(String.localizedStringWithFormat(
                    CommitLocalization.string("This will delete the local tag %@. Remote tags will not be affected."),
                    tag
                ))
            }
            .alert(CommitLocalization.string("Confirm Delete Remote Tag?"), isPresented: $showDeleteRemoteTagConfirmation) {
                Button(CommitLocalization.string("Cancel"), role: .cancel) {}
                Button(CommitLocalization.string("Delete"), role: .destructive, action: onDeleteRemoteTag)
                    .disabled(isDeletingRemoteTag)
            } message: {
                Text(String.localizedStringWithFormat(
                    CommitLocalization.string("This will delete the tag %@ on origin. Local tags will not be affected."),
                    tag
                ))
            }
    }
}
