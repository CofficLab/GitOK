import Foundation

public enum CommitRowAppearanceRules {
    public static let selectedOpacity = 0.1
    public static let hoveredOpacity = 0.08
    public static let hoverAnimationDuration = 0.15
    public static let contentSpacing = 12.0
    public static let logHashPrefixLength = 8
    public static let logMessagePrefixLength = 30

    public enum BackgroundState: Equatable, Sendable {
        case selected
        case hovered
        case clear
    }

    public struct PresentationState: Equatable, Sendable {
        public let isUnpushed: Bool
        public let hasTag: Bool
        public let canUndo: Bool
        public let canSquashThroughHead: Bool

        public init(
            isUnpushed: Bool,
            hasTag: Bool,
            canUndo: Bool,
            canSquashThroughHead: Bool
        ) {
            self.isUnpushed = isUnpushed
            self.hasTag = hasTag
            self.canUndo = canUndo
            self.canSquashThroughHead = canSquashThroughHead
        }
    }

    public static func backgroundState(isSelected: Bool, isHovered: Bool) -> BackgroundState {
        if isSelected {
            return .selected
        }

        if isHovered {
            return .hovered
        }

        return .clear
    }

    public static func isSelected(currentCommitID: String?, rowCommitID: String) -> Bool {
        currentCommitID == rowCommitID
    }

    public static func performCommitSelection<Commit>(
        _ commit: Commit,
        select: (Commit) -> Void
    ) {
        select(commit)
    }

    public static func shortLogHash(_ hash: String) -> String {
        String(hash.prefix(logHashPrefixLength))
    }

    public static func shortLogMessage(_ message: String) -> String {
        String(message.prefix(logMessagePrefixLength))
    }

    public static func commitSelectionLogMessage(hash: String, message: String) -> String {
        "👆 Commit selected - hash: \(shortLogHash(hash)), message: \(shortLogMessage(message))"
    }

    public static func pushStartLogMessage(hash: String) -> String {
        "🚀 Pushing commit \(shortLogHash(hash)) to remote"
    }

    public static func pushSuccessLogMessage(hash: String) -> String {
        "✅ Push completed successfully for commit \(shortLogHash(hash))"
    }

    public static func undoSuccessLogMessage(hash: String) -> String {
        "✅ Commit undone: \(shortLogHash(hash))"
    }

    public static func avatarLoadStartLogMessage(hash: String) -> String {
        "👤 Loading avatar users for commit: \(shortLogHash(hash))"
    }

    public static func coAuthorsParsedLogMessage(hash: String, count: Int) -> String {
        "👥 Parsed co-authors for commit \(shortLogHash(hash)): \(count) authors"
    }

    public static func commitSuccessReloadTagLogMessage(hash: String) -> String {
        "✨ Git commit success - reloading tag for commit: \(shortLogHash(hash))"
    }

    public static func presentationState(
        isFirstCommit: Bool,
        commitIndex: Int,
        isUnpushed: Bool,
        tag: String,
        commitTagCount: Int,
        parentHashCount: Int
    ) -> PresentationState {
        PresentationState(
            isUnpushed: isUnpushed,
            hasTag: tag.isEmpty == false,
            canUndo: CommitHistoryActionRules.canUndoLatestCommit(
                isFirstCommit: isFirstCommit,
                isUnpushed: isUnpushed,
                tagCount: commitTagCount,
                parentHashCount: parentHashCount
            ),
            canSquashThroughHead: CommitHistoryActionRules.canSquashThroughHead(
                commitIndex: commitIndex,
                isUnpushed: isUnpushed
            )
        )
    }
}
