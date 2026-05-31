import SwiftUI

public struct FileListContentView<FileItem: Hashable, RowContent: View>: View {
    @Binding private var selection: FileItem?

    private let files: [FileItem]
    private let sections: [FileListRules.FileSection]
    private let presentationState: FileListRules.PresentationState
    private let scrollTarget: FileItem?
    private let filesInSection: (FileListRules.FileSection) -> [FileItem]
    private let rowContent: (FileItem) -> RowContent
    private let onStageSelected: () -> Void
    private let onUnstageSelected: () -> Void
    private let onDiscardSelected: () -> Void
    private let onSelectAll: () -> Void
    private let onClearSelection: () -> Void

    public init(
        selection: Binding<FileItem?>,
        files: [FileItem],
        sections: [FileListRules.FileSection],
        presentationState: FileListRules.PresentationState,
        scrollTarget: FileItem?,
        filesInSection: @escaping (FileListRules.FileSection) -> [FileItem],
        rowContent: @escaping (FileItem) -> RowContent,
        onStageSelected: @escaping () -> Void,
        onUnstageSelected: @escaping () -> Void,
        onDiscardSelected: @escaping () -> Void,
        onSelectAll: @escaping () -> Void,
        onClearSelection: @escaping () -> Void
    ) {
        _selection = selection
        self.files = files
        self.sections = sections
        self.presentationState = presentationState
        self.scrollTarget = scrollTarget
        self.filesInSection = filesInSection
        self.rowContent = rowContent
        self.onStageSelected = onStageSelected
        self.onUnstageSelected = onUnstageSelected
        self.onDiscardSelected = onDiscardSelected
        self.onSelectAll = onSelectAll
        self.onClearSelection = onClearSelection
    }

    public var body: some View {
        ScrollViewReader { scrollProxy in
            if presentationState.showsEmptyState {
                EmptyFileFilterView(isFiltering: presentationState.emptyStateIsFiltering)
            } else {
                VStack(spacing: 0) {
                    List(selection: $selection) {
                        ForEach(sections, id: \.kind) { section in
                            Section {
                                ForEach(filesInSection(section), id: \.self) { file in
                                    rowContent(file)
                                }
                            } header: {
                                FileListSectionHeaderView(title: section.kind.title, count: section.paths.count)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .onChange(of: files) {
                        guard let scrollTarget else {
                            return
                        }
                        withAnimation {
                            scrollProxy.scrollTo(scrollTarget, anchor: .top)
                        }
                    }

                    if presentationState.showsBatchActionBar {
                        FileBatchActionBarView(
                            selectedCount: presentationState.batchActionState.selectedCount,
                            canStage: presentationState.batchActionState.canStage,
                            canUnstage: presentationState.batchActionState.canUnstage,
                            canDiscard: presentationState.batchActionState.canDiscard,
                            canSelectAll: presentationState.canSelectAll,
                            onStage: onStageSelected,
                            onUnstage: onUnstageSelected,
                            onDiscard: onDiscardSelected,
                            onSelectAll: onSelectAll,
                            onClearSelection: onClearSelection
                        )
                    }
                }
            }
        }
    }
}
