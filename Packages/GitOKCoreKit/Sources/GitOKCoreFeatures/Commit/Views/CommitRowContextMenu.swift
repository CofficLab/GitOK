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
            Label(String(localized: "Create Tag"), systemImage: "tag")
        }

        Button(action: onCreateAnnotatedTag) {
            Label(String(localized: "Create Annotated Tag"), systemImage: "tag.fill")
        }

        if hasTag {
            Button(action: onPushTag) {
                Label(String(localized: "Push Tag"), systemImage: "arrow.up.circle")
            }
            .disabled(isPushingTag)

            Button(role: .destructive, action: onDeleteRemoteTag) {
                Label(String(localized: "Delete Remote Tag"), systemImage: "icloud.slash")
            }
            .disabled(isDeletingRemoteTag)

            Button(role: .destructive, action: onDeleteTag) {
                Label(String(localized: "Delete Tag"), systemImage: "tag.slash")
            }
        }

        if canUndo {
            Button(role: .destructive, action: onUndo) {
                Label(String(localized: "Undo Commit"), systemImage: "arrow.uturn.backward")
            }
        }

        Divider()

        Button(action: onRevert) {
            Label(String(localized: "Revert This Commit"), systemImage: "arrow.counterclockwise")
        }
        .disabled(isRunningHistoryOperation)

        if canSquashThroughHead {
            Button(action: onSquash) {
                Label(String(localized: "Squash to Here"), systemImage: "arrow.triangle.merge")
            }
            .disabled(isRunningHistoryOperation)
        }

        Menu {
            Button(action: onSoftReset) {
                Label(String(localized: "Soft Reset"), systemImage: "text.badge.checkmark")
            }

            Button(action: onMixedReset) {
                Label(String(localized: "Mixed Reset"), systemImage: "list.bullet.rectangle")
            }

            Button(role: .destructive, action: onHardReset) {
                Label(String(localized: "Hard Reset"), systemImage: "trash")
            }
        } label: {
            Label(String(localized: "Reset to Here"), systemImage: "arrow.down.to.line")
        }
        .disabled(isRunningHistoryOperation)
    }
}
