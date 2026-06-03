import SwiftUI

public struct CommitRowContextMenu: View {
    private let hasTag: Bool
    private let canUndo: Bool
    private let canSquashThroughHead: Bool
    private let isPushingTag: Bool
    private let isDeletingRemoteTag: Bool
    private let isRunningHistoryOperation: Bool
    private let onCreateTag: () -> Void
    private let onCreateAnnotatedTag: () -> Void
    private let onPushTag: () -> Void
    private let onDeleteRemoteTag: () -> Void
    private let onDeleteTag: () -> Void
    private let onUndo: () -> Void
    private let onRevert: () -> Void
    private let onSquash: () -> Void
    private let onSoftReset: () -> Void
    private let onMixedReset: () -> Void
    private let onHardReset: () -> Void

    public init(
        hasTag: Bool,
        canUndo: Bool,
        canSquashThroughHead: Bool,
        isPushingTag: Bool,
        isDeletingRemoteTag: Bool,
        isRunningHistoryOperation: Bool,
        onCreateTag: @escaping () -> Void,
        onCreateAnnotatedTag: @escaping () -> Void,
        onPushTag: @escaping () -> Void,
        onDeleteRemoteTag: @escaping () -> Void,
        onDeleteTag: @escaping () -> Void,
        onUndo: @escaping () -> Void,
        onRevert: @escaping () -> Void,
        onSquash: @escaping () -> Void,
        onSoftReset: @escaping () -> Void,
        onMixedReset: @escaping () -> Void,
        onHardReset: @escaping () -> Void
    ) {
        self.hasTag = hasTag
        self.canUndo = canUndo
        self.canSquashThroughHead = canSquashThroughHead
        self.isPushingTag = isPushingTag
        self.isDeletingRemoteTag = isDeletingRemoteTag
        self.isRunningHistoryOperation = isRunningHistoryOperation
        self.onCreateTag = onCreateTag
        self.onCreateAnnotatedTag = onCreateAnnotatedTag
        self.onPushTag = onPushTag
        self.onDeleteRemoteTag = onDeleteRemoteTag
        self.onDeleteTag = onDeleteTag
        self.onUndo = onUndo
        self.onRevert = onRevert
        self.onSquash = onSquash
        self.onSoftReset = onSoftReset
        self.onMixedReset = onMixedReset
        self.onHardReset = onHardReset
    }

    public var body: some View {
        Button(action: onCreateTag) {
            Label(CommitLocalization.string("Create Tag"), systemImage: "tag")
        }

        Button(action: onCreateAnnotatedTag) {
            Label(CommitLocalization.string("Create Annotated Tag"), systemImage: "tag.fill")
        }

        if hasTag {
            Button(action: onPushTag) {
                Label(CommitLocalization.string("Push Tag"), systemImage: "arrow.up.circle")
            }
            .disabled(isPushingTag)

            Button(role: .destructive, action: onDeleteRemoteTag) {
                Label(CommitLocalization.string("Delete Remote Tag"), systemImage: "icloud.slash")
            }
            .disabled(isDeletingRemoteTag)

            Button(role: .destructive, action: onDeleteTag) {
                Label(CommitLocalization.string("Delete Tag"), systemImage: "tag.slash")
            }
        }

        if canUndo {
            Button(role: .destructive, action: onUndo) {
                Label(CommitLocalization.string("Undo Commit"), systemImage: "arrow.uturn.backward")
            }
        }

        Divider()

        Button(action: onRevert) {
            Label(CommitLocalization.string("Revert This Commit"), systemImage: "arrow.counterclockwise")
        }
        .disabled(isRunningHistoryOperation)

        if canSquashThroughHead {
            Button(action: onSquash) {
                Label(CommitLocalization.string("Squash to Here"), systemImage: "arrow.triangle.merge")
            }
            .disabled(isRunningHistoryOperation)
        }

        Menu {
            Button(action: onSoftReset) {
                Label(CommitLocalization.string("Soft Reset"), systemImage: "text.badge.checkmark")
            }

            Button(action: onMixedReset) {
                Label(CommitLocalization.string("Mixed Reset"), systemImage: "list.bullet.rectangle")
            }

            Button(role: .destructive, action: onHardReset) {
                Label(CommitLocalization.string("Hard Reset"), systemImage: "trash")
            }
        } label: {
            Label(CommitLocalization.string("Reset to Here"), systemImage: "arrow.down.to.line")
        }
        .disabled(isRunningHistoryOperation)
    }
}
