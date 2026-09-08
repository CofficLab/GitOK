import LumiUI
import ProviderProjects
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
                HStack(spacing: 4) {
                    Image(systemName: viewModel.conflictedFiles.isEmpty ? "arrow.triangle.2.circlepath" : "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(viewModel.conflictedFiles.isEmpty ? theme.primary : theme.warning)
                    Text(statusTitle)
                        .font(.appCaption)
                        .foregroundStyle(viewModel.conflictedFiles.isEmpty ? theme.primary : theme.warning)
                        .lineLimit(1)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.present()
                }
                .help(statusHelp)
            }
        }
    }

    @LumiTheme private var theme: LumiUITheme

    private var statusTitle: String {
        if viewModel.conflictedFiles.isEmpty {
            return LumiPluginLocalization.string(
                viewModel.isCherryPicking ? "Cherry-pick pending" : "Merge pending",
                bundle: .module
            )
        }
        return String(format: LumiPluginLocalization.string("Conflicts %lld", bundle: .module), viewModel.conflictedFiles.count)
    }

    private var statusHelp: String {
        if viewModel.conflictedFiles.isEmpty {
            return LumiPluginLocalization.string(
                viewModel.isCherryPicking
                    ? "Cherry-pick is ready to continue. Click to finish it."
                    : "All conflicts are resolved. Click to finish the merge.",
                bundle: .module
            )
        }
        return String(format: LumiPluginLocalization.string("There are %lld conflicted files. Click to resolve them.", bundle: .module), viewModel.conflictedFiles.count)
    }
}
