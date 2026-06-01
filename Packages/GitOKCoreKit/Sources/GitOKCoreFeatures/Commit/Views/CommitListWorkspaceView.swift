import SwiftUI

public struct CommitListWorkspaceView<WorkingStateContent: View, HistoryContent: View>: View {
    private let hasProject: Bool
    private let isInitialLoading: Bool
    private let onGeometryAppear: (CGFloat) -> Void
    private let workingStateContent: () -> WorkingStateContent
    private let historyContent: () -> HistoryContent

    public init(
        hasProject: Bool,
        isInitialLoading: Bool,
        onGeometryAppear: @escaping (CGFloat) -> Void,
        @ViewBuilder workingStateContent: @escaping () -> WorkingStateContent,
        @ViewBuilder historyContent: @escaping () -> HistoryContent
    ) {
        self.hasProject = hasProject
        self.isInitialLoading = isInitialLoading
        self.onGeometryAppear = onGeometryAppear
        self.workingStateContent = workingStateContent
        self.historyContent = historyContent
    }

    public var body: some View {
        ZStack {
            if hasProject {
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        if isInitialLoading {
                            Text("正在加载", tableName: "GitCommit")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            workingStateContent()
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
