import GitOKCoreKit
import GitOKUI
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
        AppContextMenuRow(CommitLocalization.string("Create Tag"), systemImage: "tag", action: onCreateTag)

        AppContextMenuRow(CommitLocalization.string("Create Annotated Tag"), systemImage: "tag.fill", action: onCreateAnnotatedTag)

        if hasTag {
            AppContextMenuRow(CommitLocalization.string("Push Tag"), systemImage: "arrow.up.circle", action: onPushTag)
            .disabled(isPushingTag)

            AppContextMenuRow(CommitLocalization.string("Delete Remote Tag"), systemImage: "icloud.slash", role: .destructive, action: onDeleteRemoteTag)
            .disabled(isDeletingRemoteTag)

            AppContextMenuRow(CommitLocalization.string("Delete Tag"), systemImage: "tag.slash", role: .destructive, action: onDeleteTag)
        }

        if canUndo {
            AppContextMenuRow(CommitLocalization.string("Undo Commit"), systemImage: "arrow.uturn.backward", role: .destructive, action: onUndo)
        }

        Divider()

        AppContextMenuRow(CommitLocalization.string("Revert This Commit"), systemImage: "arrow.counterclockwise", action: onRevert)
        .disabled(isRunningHistoryOperation)

        if canSquashThroughHead {
            AppContextMenuRow(CommitLocalization.string("Squash to Here"), systemImage: "arrow.triangle.merge", action: onSquash)
            .disabled(isRunningHistoryOperation)
        }

        Menu {
            AppContextMenuRow(CommitLocalization.string("Soft Reset"), systemImage: "text.badge.checkmark", action: onSoftReset)

            AppContextMenuRow(CommitLocalization.string("Mixed Reset"), systemImage: "list.bullet.rectangle", action: onMixedReset)

            AppContextMenuRow(CommitLocalization.string("Hard Reset"), systemImage: "trash", role: .destructive, action: onHardReset)
        } label: {
            Label(CommitLocalization.string("Reset to Here"), systemImage: "arrow.down.to.line")
        }
        .disabled(isRunningHistoryOperation)
    }
}
