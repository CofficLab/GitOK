import GitOKCoreKit
import SwiftUI

public struct CommitRowContentView: View {
    private let presentationState: CommitRowAppearanceRules.PresentationState
    private let currentCommitID: String?
    private let graphRow: CommitGraphPresentationRules.Row?
    private let graphLaneCount: Int
    private let message: String
    private let tag: String
    private let authors: String
    private let relativeTime: String
    private let fullDateTime: String
    private let avatarUsers: [AvatarUser]
    @Binding private var isHovered: Bool
    @Binding private var showPushPopover: Bool
    @Binding private var isPushing: Bool
    @Binding private var pushError: Error?
    @Binding private var showUndoConfirmation: Bool
    @Binding private var showRevertConfirmation: Bool
    @Binding private var showResetSoftConfirmation: Bool
    @Binding private var showResetMixedConfirmation: Bool
    @Binding private var showResetHardConfirmation: Bool
    @Binding private var showSquashConfirmation: Bool
    @Binding private var squashMessage: String
    @Binding private var showCreateTagAlert: Bool
    @Binding private var newTagName: String
    @Binding private var showCreateAnnotatedTagAlert: Bool
    @Binding private var newAnnotatedTagName: String
    @Binding private var newAnnotatedTagMessage: String
    @Binding private var showDeleteTagConfirmation: Bool
    @Binding private var showDeleteRemoteTagConfirmation: Bool
    private let isRunningHistoryOperation: Bool
    private let isCreatingTag: Bool
    private let isCreatingAnnotatedTag: Bool
    private let isDeletingTag: Bool
    private let isDeletingRemoteTag: Bool
    private let isPushingTag: Bool
    private let commitHash: String
    private let commitIndex: Int
    private let onSelect: () -> Void
    private let onAppear: () -> Void
    private let onPush: () async throws -> Void
    private let onCreateTag: () -> Void
    private let onCreateAnnotatedTag: () -> Void
    private let onPushTag: () -> Void
    private let onDeleteRemoteTagPrompt: () -> Void
    private let onDeleteTagPrompt: () -> Void
    private let onUndoPrompt: () -> Void
    private let onRevertPrompt: () -> Void
    private let onSquashPrompt: () -> Void
    private let onSoftResetPrompt: () -> Void
    private let onMixedResetPrompt: () -> Void
    private let onHardResetPrompt: () -> Void
    private let onUndo: () -> Void
    private let onRevert: () -> Void
    private let onReset: (GitResetMode) -> Void
    private let onSquash: () -> Void
    private let onCreateLightweightTag: () -> Void
    private let onCreateAnnotatedTagAction: () -> Void
    private let onDeleteLocalTag: () -> Void
    private let onDeleteRemoteTag: () -> Void

    public init(
        presentationState: CommitRowAppearanceRules.PresentationState,
        currentCommitID: String?,
        graphRow: CommitGraphPresentationRules.Row?,
        graphLaneCount: Int,
        message: String,
        tag: String,
        authors: String,
        relativeTime: String,
        fullDateTime: String,
        avatarUsers: [AvatarUser],
        isHovered: Binding<Bool>,
        showPushPopover: Binding<Bool>,
        isPushing: Binding<Bool>,
        pushError: Binding<Error?>,
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
        isPushingTag: Bool,
        commitHash: String,
        commitIndex: Int,
        onSelect: @escaping () -> Void,
        onAppear: @escaping () -> Void,
        onPush: @escaping () async throws -> Void,
        onCreateTag: @escaping () -> Void,
        onCreateAnnotatedTag: @escaping () -> Void,
        onPushTag: @escaping () -> Void,
        onDeleteRemoteTagPrompt: @escaping () -> Void,
        onDeleteTagPrompt: @escaping () -> Void,
        onUndoPrompt: @escaping () -> Void,
        onRevertPrompt: @escaping () -> Void,
        onSquashPrompt: @escaping () -> Void,
        onSoftResetPrompt: @escaping () -> Void,
        onMixedResetPrompt: @escaping () -> Void,
        onHardResetPrompt: @escaping () -> Void,
        onUndo: @escaping () -> Void,
        onRevert: @escaping () -> Void,
        onReset: @escaping (GitResetMode) -> Void,
        onSquash: @escaping () -> Void,
        onCreateLightweightTag: @escaping () -> Void,
        onCreateAnnotatedTagAction: @escaping () -> Void,
        onDeleteLocalTag: @escaping () -> Void,
        onDeleteRemoteTag: @escaping () -> Void
    ) {
        self.presentationState = presentationState
        self.currentCommitID = currentCommitID
        self.graphRow = graphRow
        self.graphLaneCount = graphLaneCount
        self.message = message
        self.tag = tag
        self.authors = authors
        self.relativeTime = relativeTime
        self.fullDateTime = fullDateTime
        self.avatarUsers = avatarUsers
        _isHovered = isHovered
        _showPushPopover = showPushPopover
        _isPushing = isPushing
        _pushError = pushError
        _showUndoConfirmation = showUndoConfirmation
        _showRevertConfirmation = showRevertConfirmation
        _showResetSoftConfirmation = showResetSoftConfirmation
        _showResetMixedConfirmation = showResetMixedConfirmation
        _showResetHardConfirmation = showResetHardConfirmation
        _showSquashConfirmation = showSquashConfirmation
        _squashMessage = squashMessage
        _showCreateTagAlert = showCreateTagAlert
        _newTagName = newTagName
        _showCreateAnnotatedTagAlert = showCreateAnnotatedTagAlert
        _newAnnotatedTagName = newAnnotatedTagName
        _newAnnotatedTagMessage = newAnnotatedTagMessage
        _showDeleteTagConfirmation = showDeleteTagConfirmation
        _showDeleteRemoteTagConfirmation = showDeleteRemoteTagConfirmation
        self.isRunningHistoryOperation = isRunningHistoryOperation
        self.isCreatingTag = isCreatingTag
        self.isCreatingAnnotatedTag = isCreatingAnnotatedTag
        self.isDeletingTag = isDeletingTag
        self.isDeletingRemoteTag = isDeletingRemoteTag
        self.isPushingTag = isPushingTag
        self.commitHash = commitHash
        self.commitIndex = commitIndex
        self.onSelect = onSelect
        self.onAppear = onAppear
        self.onPush = onPush
        self.onCreateTag = onCreateTag
        self.onCreateAnnotatedTag = onCreateAnnotatedTag
        self.onPushTag = onPushTag
        self.onDeleteRemoteTagPrompt = onDeleteRemoteTagPrompt
        self.onDeleteTagPrompt = onDeleteTagPrompt
        self.onUndoPrompt = onUndoPrompt
        self.onRevertPrompt = onRevertPrompt
        self.onSquashPrompt = onSquashPrompt
        self.onSoftResetPrompt = onSoftResetPrompt
        self.onMixedResetPrompt = onMixedResetPrompt
        self.onHardResetPrompt = onHardResetPrompt
        self.onUndo = onUndo
        self.onRevert = onRevert
        self.onReset = onReset
        self.onSquash = onSquash
        self.onCreateLightweightTag = onCreateLightweightTag
        self.onCreateAnnotatedTagAction = onCreateAnnotatedTagAction
        self.onDeleteLocalTag = onDeleteLocalTag
        self.onDeleteRemoteTag = onDeleteRemoteTag
    }

    public var body: some View {
        VStack(spacing: 0) {
            Button(action: onSelect) {
                HStack(alignment: .center, spacing: CommitRowAppearanceRules.contentSpacing) {
                    CommitRowSummaryView(
                        graphRow: graphRow,
                        graphLaneCount: graphLaneCount,
                        message: message,
                        tag: tag,
                        authors: authors,
                        relativeTime: relativeTime,
                        fullDateTime: fullDateTime,
                        avatarUsers: avatarUsers
                    )

                    if presentationState.isUnpushed {
                        UnpushedCommitActionsView(
                            canUndo: presentationState.canUndo,
                            showPushPopover: $showPushPopover,
                            isPushing: $isPushing,
                            pushError: $pushError,
                            onUndo: onUndoPrompt,
                            onPush: onPush
                        )
                    }

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .background(CommitRowBackgroundView(
                isSelected: CommitRowAppearanceRules.isSelected(
                    currentCommitID: currentCommitID,
                    rowCommitID: commitHash
                ),
                isHovered: isHovered
            ))
            .onHover { hovering in
                withAnimation(.easeInOut(duration: CommitRowAppearanceRules.hoverAnimationDuration)) {
                    isHovered = hovering
                }
            }
            .onAppear(perform: onAppear)
            .contextMenu {
                CommitRowContextMenu(
                    hasTag: presentationState.hasTag,
                    canUndo: presentationState.canUndo,
                    canSquashThroughHead: presentationState.canSquashThroughHead,
                    isPushingTag: isPushingTag,
                    isDeletingRemoteTag: isDeletingRemoteTag,
                    isRunningHistoryOperation: isRunningHistoryOperation,
                    onCreateTag: onCreateTag,
                    onCreateAnnotatedTag: onCreateAnnotatedTag,
                    onPushTag: onPushTag,
                    onDeleteRemoteTag: onDeleteRemoteTagPrompt,
                    onDeleteTag: onDeleteTagPrompt,
                    onUndo: onUndoPrompt,
                    onRevert: onRevertPrompt,
                    onSquash: onSquashPrompt,
                    onSoftReset: onSoftResetPrompt,
                    onMixedReset: onMixedResetPrompt,
                    onHardReset: onHardResetPrompt
                )
            }
            .commitRowAlerts(
                showUndoConfirmation: $showUndoConfirmation,
                showRevertConfirmation: $showRevertConfirmation,
                showResetSoftConfirmation: $showResetSoftConfirmation,
                showResetMixedConfirmation: $showResetMixedConfirmation,
                showResetHardConfirmation: $showResetHardConfirmation,
                showSquashConfirmation: $showSquashConfirmation,
                squashMessage: $squashMessage,
                showCreateTagAlert: $showCreateTagAlert,
                newTagName: $newTagName,
                showCreateAnnotatedTagAlert: $showCreateAnnotatedTagAlert,
                newAnnotatedTagName: $newAnnotatedTagName,
                newAnnotatedTagMessage: $newAnnotatedTagMessage,
                showDeleteTagConfirmation: $showDeleteTagConfirmation,
                showDeleteRemoteTagConfirmation: $showDeleteRemoteTagConfirmation,
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
                onCreateAnnotatedTag: onCreateAnnotatedTagAction,
                onDeleteLocalTag: onDeleteLocalTag,
                onDeleteRemoteTag: onDeleteRemoteTag
            )

            Divider()
        }
    }
}
