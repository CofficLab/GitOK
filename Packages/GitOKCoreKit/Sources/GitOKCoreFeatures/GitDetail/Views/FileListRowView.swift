import SwiftUI

public struct FileListRowView<FileItem: Hashable>: View {
    private let file: FileItem
    private let path: String
    private let changeType: String
    private let projectURL: URL?
    private let canEditWorkingTree: Bool
    private let stageState: FileStageState
    private let showsStageBadge: Bool
    private let isBatchSelected: Bool
    @Binding private var hoveredFile: FileItem?
    private let isSelected: Bool
    private let onDiscardChanges: () -> Void
    private let onToggleBatchSelection: () -> Void
    private let onStage: () -> Void
    private let onUnstage: () -> Void
    private let onSelect: () -> Void
    private let onMoveCommand: (MoveCommandDirection) -> Void
    private let onDeleteCommand: () -> Void

    public init(
        file: FileItem,
        path: String,
        changeType: String,
        projectURL: URL?,
        canEditWorkingTree: Bool,
        stageState: FileStageState,
        showsStageBadge: Bool,
        isBatchSelected: Bool,
        hoveredFile: Binding<FileItem?>,
        isSelected: Bool,
        onDiscardChanges: @escaping () -> Void,
        onToggleBatchSelection: @escaping () -> Void,
        onStage: @escaping () -> Void,
        onUnstage: @escaping () -> Void,
        onSelect: @escaping () -> Void,
        onMoveCommand: @escaping (MoveCommandDirection) -> Void,
        onDeleteCommand: @escaping () -> Void
    ) {
        self.file = file
        self.path = path
        self.changeType = changeType
        self.projectURL = projectURL
        self.canEditWorkingTree = canEditWorkingTree
        self.stageState = stageState
        self.showsStageBadge = showsStageBadge
        self.isBatchSelected = isBatchSelected
        _hoveredFile = hoveredFile
        self.isSelected = isSelected
        self.onDiscardChanges = onDiscardChanges
        self.onToggleBatchSelection = onToggleBatchSelection
        self.onStage = onStage
        self.onUnstage = onUnstage
        self.onSelect = onSelect
        self.onMoveCommand = onMoveCommand
        self.onDeleteCommand = onDeleteCommand
    }

    public var body: some View {
        FileTile(
            file: GitDetailFileItem(path: path, changeType: changeType),
            projectURL: projectURL,
            onDiscardChanges: canEditWorkingTree ? onDiscardChanges : nil,
            stageState: stageState,
            showsStageBadge: showsStageBadge,
            isBatchSelected: isBatchSelected,
            onToggleBatchSelection: canEditWorkingTree ? onToggleBatchSelection : nil,
            onStage: canEditWorkingTree ? onStage : nil,
            onUnstage: canEditWorkingTree ? onUnstage : nil,
            onSelect: onSelect,
            onHoverChanged: { hovering in
                withAnimation(.easeInOut(duration: FileListRules.hoverAnimationDuration)) {
                    if hovering {
                        hoveredFile = file
                    } else if hoveredFile == file {
                        hoveredFile = nil
                    }
                }
            }
        )
        .tag(file as FileItem?)
        .listRowInsets(.init())
        .listRowBackground(FileListRowBackgroundView(isHovered: hoveredFile == file))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .onMoveCommand(perform: onMoveCommand)
        .onDeleteCommand(perform: onDeleteCommand)
    }
}
