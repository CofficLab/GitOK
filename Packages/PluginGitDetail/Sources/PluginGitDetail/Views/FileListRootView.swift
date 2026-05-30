import SwiftUI

public struct FileListRootView<ListContent: View>: View {
    @Binding private var filterText: String
    @Binding private var showDiscardFileAlert: Bool
    @Binding private var showDiscardAllAlert: Bool
    @Binding private var showDiscardSelectedAlert: Bool

    private let fileCount: Int
    private let isLoading: Bool
    private let presentationState: FileListRules.PresentationState
    private let errorMessage: String?
    private let discardFileAlertMessage: String
    private let onRetry: () -> Void
    private let onDiscardAllPrompt: () -> Void
    private let onCancelDiscardFile: () -> Void
    private let onDiscardFile: () -> Void
    private let onDiscardAll: () -> Void
    private let onDiscardSelected: () -> Void
    private let listContent: () -> ListContent

    public init(
        filterText: Binding<String>,
        showDiscardFileAlert: Binding<Bool>,
        showDiscardAllAlert: Binding<Bool>,
        showDiscardSelectedAlert: Binding<Bool>,
        fileCount: Int,
        isLoading: Bool,
        presentationState: FileListRules.PresentationState,
        errorMessage: String?,
        discardFileAlertMessage: String,
        onRetry: @escaping () -> Void,
        onDiscardAllPrompt: @escaping () -> Void,
        onCancelDiscardFile: @escaping () -> Void,
        onDiscardFile: @escaping () -> Void,
        onDiscardAll: @escaping () -> Void,
        onDiscardSelected: @escaping () -> Void,
        @ViewBuilder listContent: @escaping () -> ListContent
    ) {
        _filterText = filterText
        _showDiscardFileAlert = showDiscardFileAlert
        _showDiscardAllAlert = showDiscardAllAlert
        _showDiscardSelectedAlert = showDiscardSelectedAlert
        self.fileCount = fileCount
        self.isLoading = isLoading
        self.presentationState = presentationState
        self.errorMessage = errorMessage
        self.discardFileAlertMessage = discardFileAlertMessage
        self.onRetry = onRetry
        self.onDiscardAllPrompt = onDiscardAllPrompt
        self.onCancelDiscardFile = onCancelDiscardFile
        self.onDiscardFile = onDiscardFile
        self.onDiscardAll = onDiscardAll
        self.onDiscardSelected = onDiscardSelected
        self.listContent = listContent
    }

    public var body: some View {
        VStack(spacing: 0) {
            FileListToolbarView(
                filterText: $filterText,
                fileCount: fileCount,
                isLoading: isLoading,
                showsDiscardAll: presentationState.showsDiscardAll,
                onDiscardAll: onDiscardAllPrompt
            )

            if let errorMessage {
                FileListErrorView(message: errorMessage, onRetry: onRetry)
            } else {
                listContent()
            }
        }
        .alert(FileListRules.discardFileAlertText().title, isPresented: $showDiscardFileAlert) {
            Button(FileListRules.discardFileAlertText().cancelButtonTitle, role: .cancel, action: onCancelDiscardFile)
            Button(FileListRules.discardFileAlertText().destructiveButtonTitle, role: .destructive, action: onDiscardFile)
        } message: {
            Text(discardFileAlertMessage)
        }
        .alert(FileListRules.discardAllAlertText().title, isPresented: $showDiscardAllAlert) {
            Button(FileListRules.discardAllAlertText().cancelButtonTitle, role: .cancel) { }
            Button(FileListRules.discardAllAlertText().destructiveButtonTitle, role: .destructive, action: onDiscardAll)
        } message: {
            Text(presentationState.discardAllAlertMessage)
        }
        .alert(FileListRules.discardSelectedAlertText().title, isPresented: $showDiscardSelectedAlert) {
            Button(FileListRules.discardSelectedAlertText().cancelButtonTitle, role: .cancel) { }
            Button(FileListRules.discardSelectedAlertText().destructiveButtonTitle, role: .destructive, action: onDiscardSelected)
        } message: {
            Text(presentationState.discardSelectedAlertMessage)
        }
    }
}
