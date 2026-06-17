import SwiftUI

public struct CommitListWorkspaceView<HistoryContent: View>: View {
    private let hasProject: Bool
    private let isInitialLoading: Bool
    private let onGeometryAppear: (CGFloat) -> Void
    private let historyContent: () -> HistoryContent

    public init(
        hasProject: Bool,
        isInitialLoading: Bool,
        onGeometryAppear: @escaping (CGFloat) -> Void,
        @ViewBuilder historyContent: @escaping () -> HistoryContent
    ) {
        self.hasProject = hasProject
        self.isInitialLoading = isInitialLoading
        self.onGeometryAppear = onGeometryAppear
        self.historyContent = historyContent
    }

    public var body: some View {
        ZStack {
            if hasProject {
                GeometryReader { geometry in
                    Group {
                        if isInitialLoading {
                            Text("正在加载")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            historyContent()
                        }
                    }
                    .onAppear {
                        onGeometryAppear(geometry.size.height)
                    }
                }
            }
        }
    }
}
