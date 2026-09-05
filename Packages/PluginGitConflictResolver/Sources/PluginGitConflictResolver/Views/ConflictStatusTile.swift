import LumiUI
import ProviderProjects
import SwiftUI

/// 冲突状态 tile：仅在存在待解决冲突时显示（⚠️ + 冲突数）；
/// 无冲突时渲染 EmptyView，状态栏不占位（对齐旧版 ConflictStatusTile）。
public struct ConflictStatusTile: View {
    let projects: any ProjectProviding
    @ObservedObject private var viewModel: GitConflictResolverViewModel
    @State private var isPresented = false

    public init(projects: any ProjectProviding, viewModel: GitConflictResolverViewModel) {
        self.projects = projects
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }

    public var body: some View {
        Group {
            if viewModel.currentProjectURL != nil && viewModel.isOperationInProgress {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(theme.warning)
                    Text(String(format: LumiPluginLocalization.string("Conflicts %lld", bundle: .module), viewModel.conflictedFiles.count))
                        .font(.appCaption)
                        .foregroundStyle(theme.warning)
                        .lineLimit(1)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    isPresented.toggle()
                }
                .help(String(format: LumiPluginLocalization.string("There are %lld conflicted files. Click to resolve them.", bundle: .module), viewModel.conflictedFiles.count))
                .popover(isPresented: $isPresented, arrowEdge: .bottom) {
                    ConflictResolverList(projects: projects, viewModel: viewModel)
                        .frame(width: 560, height: 480)
                }
            }
        }
    }

    @LumiTheme private var theme: LumiUITheme
}
