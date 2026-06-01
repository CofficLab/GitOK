import SwiftUI

public enum GitDetailLayoutMetrics {
    public static let headerHorizontalPadding: CGFloat = 8
    public static let headerVerticalPadding: CGFloat = 8
    public static let fileListIdealWidth: CGFloat = 200
    public static let fileListMinWidth: CGFloat = 200
    public static let fileListMaxWidth: CGFloat = 420
}

public struct GitDetailContentLayout<HeaderContent: View, FileListContent: View, FileDetailContent: View, EmptyContent: View>: View {
    private let showsHeader: Bool
    private let showsFileSplit: Bool
    private let headerContent: () -> HeaderContent
    private let fileListContent: () -> FileListContent
    private let fileDetailContent: () -> FileDetailContent
    private let emptyContent: () -> EmptyContent

    public init(
        showsHeader: Bool,
        showsFileSplit: Bool,
        @ViewBuilder headerContent: @escaping () -> HeaderContent,
        @ViewBuilder fileListContent: @escaping () -> FileListContent,
        @ViewBuilder fileDetailContent: @escaping () -> FileDetailContent,
        @ViewBuilder emptyContent: @escaping () -> EmptyContent
    ) {
        self.showsHeader = showsHeader
        self.showsFileSplit = showsFileSplit
        self.headerContent = headerContent
        self.fileListContent = fileListContent
        self.fileDetailContent = fileDetailContent
        self.emptyContent = emptyContent
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showsHeader {
                headerContent()
                    .padding(.horizontal, GitDetailLayoutMetrics.headerHorizontalPadding)
                    .padding(.vertical, GitDetailLayoutMetrics.headerVerticalPadding)
            }

            if showsFileSplit {
                HSplitView {
                    fileListContent()
                        .frame(idealWidth: GitDetailLayoutMetrics.fileListIdealWidth)
                        .frame(
                            minWidth: GitDetailLayoutMetrics.fileListMinWidth,
                            maxWidth: GitDetailLayoutMetrics.fileListMaxWidth
                        )
                        .layoutPriority(1)

                    fileDetailContent()
                }
                .padding(.horizontal, 0)
                .padding(.vertical, 0)
            } else {
                emptyContent()
            }
        }
    }
}
