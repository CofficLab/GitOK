import LumiUI
import ProviderProjects
import SwiftUI

/// .gitignore 查看器：等宽字体展示内容，可选中复制
/// （对齐旧版 GitIgnoreViewer 的查看能力）。
public struct GitIgnoreViewer: View {
    let projects: any ProjectProviding
    @Environment(\.dismiss) private var dismiss

    @State private var content = ""
    @State private var isLoading = true

    public init(projects: any ProjectProviding) {
        self.projects = projects
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView([.vertical, .horizontal]) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    Text(content)
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
        .onAppear(perform: load)
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
            AppButton("Close", style: .secondary, size: .small) {
                dismiss()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func load() {
        guard let url = projects.currentProject?.url else {
            content = ""
            isLoading = false
            return
        }
        let gitignore = url.appendingPathComponent(".gitignore")
        Task.detached(priority: .userInitiated) {
            let text = (try? String(contentsOf: gitignore, encoding: .utf8)) ?? ""
            await MainActor.run {
                content = text
                isLoading = false
            }
        }
    }

    @LumiTheme private var theme: LumiUITheme
}
