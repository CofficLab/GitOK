import LumiUI
import ProviderProjects
import SwiftUI

/// .gitignore 查看器：等宽字体展示内容，可选中复制
/// （对齐旧版 GitIgnoreViewer 的查看能力）。
public struct GitIgnoreViewer: View {
    let projects: any ProjectProviding
    @Environment(\.dismiss) private var dismiss

    @State private var model: GitIgnoreViewerModel

    public init(projects: any ProjectProviding) {
        self.projects = projects
        _model = State(initialValue: GitIgnoreViewerModel(
            file: GitIgnoreFile(repositoryRoot: projects.currentProject?.url)
        ))
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView([.vertical, .horizontal]) {
                if model.isLoading {
                    GitIgnoreSkeletonView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    Text(model.content)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 600, minHeight: 400)
        .task { await model.load() }
    }

    private var header: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "doc.text.fill")
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(".gitignore")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text(projects.currentProject?.title ?? "")
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                }
            }
            Spacer()
            AppButton(GitIgnoreLocalization.string("Close", bundle: .module), style: .secondary, size: .small) {
                dismiss()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @LumiTheme private var theme: LumiUITheme
}
