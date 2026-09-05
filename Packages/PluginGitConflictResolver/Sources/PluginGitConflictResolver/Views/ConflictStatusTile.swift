import LumiUI
import ProviderProjects
import SwiftUI

/// 冲突状态 tile：合并中显示冲突数（红），否则 Merge OK（对齐旧版 ConflictStatusTile）。
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
            if viewModel.currentProjectURL != nil {
                HStack(spacing: 4) {
                    Image(systemName: viewModel.isOperationInProgress ? "exclamationmark.triangle.fill" : "checkmark.circle")
                        .font(.system(size: 10))
                        .foregroundStyle(viewModel.isOperationInProgress ? theme.warning : theme.textTertiary)
                    Text(viewModel.isOperationInProgress ? String(format: LumiPluginLocalization.string("Conflicts %lld", bundle: .module), viewModel.conflictedFiles.count) : LumiPluginLocalization.string("Merge OK", bundle: .module))
                        .font(.appCaption)
                        .foregroundStyle(viewModel.isOperationInProgress ? theme.warning : theme.textTertiary)
                        .lineLimit(1)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    isPresented.toggle()
                }
                .help(viewModel.isOperationInProgress
                    ? String(format: LumiPluginLocalization.string("There are %lld conflicted files. Click to resolve them.", bundle: .module), viewModel.conflictedFiles.count)
                    : LumiPluginLocalization.string("No merge conflicts", bundle: .module))
                .popover(isPresented: $isPresented, arrowEdge: .bottom) {
                    ConflictResolverList(projects: projects, viewModel: viewModel)
                        .frame(width: 560, height: 480)
                }
            }
        }
    }

    @LumiTheme private var theme: LumiUITheme
}
