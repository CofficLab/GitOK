import LumiUI
import ProviderProjects
import ProviderStatusBar
import SwiftUI

/// 冲突/合并状态 tile：显示待解决冲突，或提示一个已解决冲突但尚未
/// 完成的合并操作。
public struct ConflictStatusTile: View {
    @ObservedObject private var viewModel: GitConflictResolverViewModel

    public init(projects: any ProjectProviding, viewModel: GitConflictResolverViewModel) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }

    public var body: some View {
        Group {
            if viewModel.currentProjectURL != nil && viewModel.isOperationInProgress {
                AppStatusBarTile(
                    systemImage: viewModel.conflictedFiles.isEmpty ? "arrow.triangle.2.circlepath" : "exclamationmark.triangle.fill",
                    tint: viewModel.conflictedFiles.isEmpty ? theme.primary : theme.warning,
                    action: { viewModel.present() }
                ) {
                    Text(statusTitle)
                        .lineLimit(1)
                }
                .help(statusHelp)
            }
        }
    }

    @LumiTheme private var theme: LumiUITheme

    private var statusTitle: String {
        if viewModel.conflictedFiles.isEmpty {
            return pluginLocalization.string(viewModel.isCherryPicking ? "Cherry-pick pending" : "Merge pending")
        }
        return String(format: pluginLocalization.string("Conflicts %lld"), viewModel.conflictedFiles.count)
    }

    private var statusHelp: String {
        if viewModel.conflictedFiles.isEmpty {
            return pluginLocalization.string(viewModel.isCherryPicking
                    ? "Cherry-pick is ready to continue. Click to finish it."
                    : "All conflicts are resolved. Click to finish the merge.")
        }
        return String(format: pluginLocalization.string("There are %lld conflicted files. Click to resolve them."), viewModel.conflictedFiles.count)
    }
}
