import GitCoreKit
import GitOKUI
import SwiftUI

public struct WorkingStateConflictState: Equatable, Sendable {
    public let isMerging: Bool
    public let mergeBranchName: String?
    public let files: [GitMergeFile]

    public init(
        isMerging: Bool,
        mergeBranchName: String? = nil,
        files: [GitMergeFile] = []
    ) {
        self.isMerging = isMerging
        self.mergeBranchName = mergeBranchName
        self.files = files
    }

    public static let inactive = WorkingStateConflictState(isMerging: false)

    public var unresolvedCount: Int {
        files.filter { $0.state == .unresolved }.count
    }

    public var pendingStageCount: Int {
        files.filter { $0.state == .pendingStage }.count
    }

    public var stagedCount: Int {
        files.filter { $0.state == .staged }.count
    }

    public var canContinueMerge: Bool {
        guard isMerging else { return false }
        if unresolvedCount > 0 || pendingStageCount > 0 {
            return false
        }
        if files.isEmpty {
            return true
        }
        return files.allSatisfy { $0.state == .staged }
    }

    public var statusText: String {
        if unresolvedCount > 0 {
            return String.localizedStringWithFormat(
                CommitLocalization.string(unresolvedCount == 1 ? "%lld file still has conflicts" : "%lld files still have conflicts"),
                unresolvedCount
            )
        }

        if pendingStageCount > 0 {
            return String.localizedStringWithFormat(
                CommitLocalization.string(pendingStageCount == 1 ? "%lld resolved file needs staging" : "%lld resolved files need staging"),
                pendingStageCount
            )
        }

        if canContinueMerge {
            return files.isEmpty
                ? CommitLocalization.string("Merge is ready to complete")
                : CommitLocalization.string("All conflicts resolved")
        }

        return CommitLocalization.string("Merge is waiting for resolution")
    }

    public var continueHelp: String {
        if unresolvedCount > 0 {
            return CommitLocalization.string("Resolve all conflicts before continuing")
        }

        if pendingStageCount > 0 {
            return CommitLocalization.string("Stage resolved files before continuing")
        }

        return CommitLocalization.string("Complete the merge")
    }
}

public enum WorkingStateConflictRules {
    public static let defaultVisibleFileLimit = 80

    public static func mergeFiles(
        unresolvedPaths: Set<String>,
        statusEntries: [GitStatusEntry]
    ) -> [GitMergeFile] {
        let unstagedPaths = Set(statusEntries.filter { $0.workTreeStatus != " " }.map(\.path))
        let stagedPaths = Set(statusEntries.filter { $0.indexStatus != " " }.map(\.path))
        let allPaths = unresolvedPaths.union(unstagedPaths).union(stagedPaths).sorted()

        return allPaths.map { path in
            if unresolvedPaths.contains(path) {
                return GitMergeFile(path: path, state: .unresolved)
            }

            if unstagedPaths.contains(path) {
                return GitMergeFile(path: path, state: .pendingStage)
            }

            return GitMergeFile(path: path, state: .staged)
        }
    }

    public static func visibleFiles(
        from files: [GitMergeFile],
        limit: Int = defaultVisibleFileLimit
    ) -> ArraySlice<GitMergeFile> {
        files.prefix(max(0, limit))
    }

    public static func hiddenFileCount(
        totalCount: Int,
        limit: Int = defaultVisibleFileLimit
    ) -> Int {
        max(0, totalCount - max(0, limit))
    }
}

public struct WorkingStateConflictPanel: View {
    @GitOKMotionPreferenceReader private var motionPreference

    private let state: WorkingStateConflictState
    private let isPerformingAction: Bool
    private let activePath: String?
    private let onOpen: (String) -> Void
    private let onReveal: (String) -> Void
    private let onStage: (String) -> Void
    private let onUseOurs: (String) -> Void
    private let onUseTheirs: (String) -> Void
    private let onContinue: () -> Void
    private let onAbort: () -> Void

    public init(
        state: WorkingStateConflictState,
        isPerformingAction: Bool,
        activePath: String?,
        onOpen: @escaping (String) -> Void,
        onReveal: @escaping (String) -> Void,
        onStage: @escaping (String) -> Void,
        onUseOurs: @escaping (String) -> Void,
        onUseTheirs: @escaping (String) -> Void,
        onContinue: @escaping () -> Void,
        onAbort: @escaping () -> Void
    ) {
        self.state = state
        self.isPerformingAction = isPerformingAction
        self.activePath = activePath
        self.onOpen = onOpen
        self.onReveal = onReveal
        self.onStage = onStage
        self.onUseOurs = onUseOurs
        self.onUseTheirs = onUseTheirs
        self.onContinue = onContinue
        self.onAbort = onAbort
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            VStack(spacing: 8) {
                ForEach(visibleFiles) { file in
                    WorkingStateConflictFileRow(
                        file: file,
                        isBusy: isPerformingAction && activePath == file.path,
                        onOpen: { onOpen(file.path) },
                        onReveal: { onReveal(file.path) },
                        onStage: { onStage(file.path) },
                        onUseOurs: { onUseOurs(file.path) },
                        onUseTheirs: { onUseTheirs(file.path) }
                    )
                }

                if hiddenConflictFileCount > 0 {
                    hiddenConflictSummary
                }
            }
        }
        .padding(14)
        .background(Color(.controlBackgroundColor))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color(.separatorColor))
                .frame(height: 1)
        }
        .animation(panelAnimation, value: state.files.count)
        .animation(panelAnimation, value: isPerformingAction)
    }

    private var visibleFiles: ArraySlice<GitMergeFile> {
        WorkingStateConflictRules.visibleFiles(from: state.files)
    }

    private var hiddenConflictFileCount: Int {
        WorkingStateConflictRules.hiddenFileCount(totalCount: state.files.count)
    }

    private var hiddenConflictSummary: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 24, height: 24)
                .background(Color.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 6, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(String.localizedStringWithFormat(
                    CommitLocalization.string("Showing first %lld conflict files"),
                    WorkingStateConflictRules.defaultVisibleFileLimit
                ))
                .font(.system(size: 12, weight: .semibold))

                Text(String.localizedStringWithFormat(
                    CommitLocalization.string("%lld more conflict files are hidden to keep GitOK responsive"),
                    hiddenConflictFileCount
                ))
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(2)
            }

            Spacer(minLength: 8)
        }
        .padding(.vertical, 4)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: state.canContinueMerge ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(state.canContinueMerge ? Color.green : Color.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text(CommitLocalization.string("Resolve merge conflicts"))
                    .font(.system(size: 14, weight: .semibold))

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            HStack(spacing: 8) {
                AppButton(
                    CommitLocalization.string("Abort Merge"),
                    systemImage: "xmark.octagon",
                    style: .destructive,
                    size: .small
                ) {
                    onAbort()
                }
                .disabled(isPerformingAction)

                AppButton(
                    CommitLocalization.string("Continue Merge"),
                    systemImage: "checkmark.circle",
                    style: .primary,
                    size: .small
                ) {
                    onContinue()
                }
                .disabled(isPerformingAction || state.canContinueMerge == false)
                .help(state.continueHelp)
            }
        }
    }

    private var subtitle: String {
        let fileText = String.localizedStringWithFormat(
            CommitLocalization.string(state.files.count == 1 ? "%lld conflicted file" : "%lld conflicted files"),
            state.files.count
        )

        if let mergeBranchName = state.mergeBranchName, mergeBranchName.isEmpty == false {
            return "\(fileText). \(state.statusText). \(CommitLocalization.string("Merging")) \(mergeBranchName)."
        }

        return "\(fileText). \(state.statusText)."
    }

    private var panelAnimation: Animation? {
        motionPreference.allowsMotion ? .easeInOut(duration: 0.20) : nil
    }
}

private struct WorkingStateConflictFileRow: View {
    let file: GitMergeFile
    let isBusy: Bool
    let onOpen: () -> Void
    let onReveal: () -> Void
    let onStage: () -> Void
    let onUseOurs: () -> Void
    let onUseTheirs: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: file.state.conflictIconName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(file.state.conflictTint)
                .frame(width: 24, height: 24)
                .background(file.state.conflictTint.opacity(0.12), in: RoundedRectangle(cornerRadius: 6, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text((file.path as NSString).lastPathComponent)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)

                HStack(spacing: 5) {
                    Text(file.state.conflictTitle)
                        .foregroundStyle(file.state.conflictTint)
                    Text("•")
                    Text(file.path)
                }
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer(minLength: 8)

            HStack(spacing: 6) {
                iconButton("square.and.pencil", CommitLocalization.string("Open in editor"), onOpen)
                iconButton("folder", CommitLocalization.string("Reveal in Finder"), onReveal)

                Menu {
                    AppContextMenuRow(CommitLocalization.string("Use Ours"), systemImage: "arrow.left.circle", action: onUseOurs)
                    AppContextMenuRow(CommitLocalization.string("Use Theirs"), systemImage: "arrow.right.circle", action: onUseTheirs)
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .frame(width: 26, height: 26)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .disabled(isBusy)
                .help(CommitLocalization.string("Choose a side"))

                Button {
                    onStage()
                } label: {
                    if isBusy {
                        AppSpinningIcon(size: 12)
                    } else {
                        Image(systemName: file.state == .staged ? "checkmark.circle.fill" : "checkmark.circle")
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(file.state == .staged ? Color.green : file.state.conflictTint)
                .frame(width: 26, height: 26)
                .disabled(isBusy || file.state == .staged)
                .help(file.state == .unresolved ? CommitLocalization.string("Mark resolved and stage") : CommitLocalization.string("Stage resolved file"))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(.textBackgroundColor).opacity(0.48), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func iconButton(_ systemImage: String, _ help: String, _ action: @escaping () -> Void) -> some View {
        AppIconButton(
            systemImage: systemImage,
            tint: .secondary,
            size: .compact,
            action: action
        )
        .frame(width: 26, height: 26)
        .disabled(isBusy)
        .help(help)
    }
}

private extension GitMergeFileState {
    var conflictTitle: String {
        switch self {
        case .unresolved:
            CommitLocalization.string("Unresolved")
        case .pendingStage:
            CommitLocalization.string("Ready to stage")
        case .staged:
            CommitLocalization.string("Staged")
        }
    }

    var conflictIconName: String {
        switch self {
        case .unresolved:
            "exclamationmark.triangle.fill"
        case .pendingStage:
            "square.and.arrow.down"
        case .staged:
            "checkmark.circle.fill"
        }
    }

    var conflictTint: Color {
        switch self {
        case .unresolved:
            .orange
        case .pendingStage:
            .blue
        case .staged:
            .green
        }
    }
}
