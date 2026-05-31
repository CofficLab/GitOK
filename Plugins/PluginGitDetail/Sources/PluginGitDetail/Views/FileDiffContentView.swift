import SwiftUI

public struct FileDiffContentView<EmptyContent: View, LargeContent: View, RenderContent: View>: View {
    private let mode: GitDetailDiffDisplayRules.DiffContentMode
    private let emptyContent: () -> EmptyContent
    private let largeContent: () -> LargeContent
    private let renderContent: () -> RenderContent

    public init(
        mode: GitDetailDiffDisplayRules.DiffContentMode,
        @ViewBuilder emptyContent: @escaping () -> EmptyContent,
        @ViewBuilder largeContent: @escaping () -> LargeContent,
        @ViewBuilder renderContent: @escaping () -> RenderContent
    ) {
        self.mode = mode
        self.emptyContent = emptyContent
        self.largeContent = largeContent
        self.renderContent = renderContent
    }

    public var body: some View {
        switch mode {
        case .empty:
            emptyContent()
        case .large:
            largeContent()
        case .render:
            renderContent()
        }
    }
}
