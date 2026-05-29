import GitOKPluginKit
import SwiftUI

struct GitIgnoreStatusIcon: View {
    @Environment(\.gitOKProjectURL) private var projectURL

    @State private var isSheetPresented = false
    @State private var hasGitIgnore = false

    var body: some View {
        Button {
            if hasGitIgnore {
                isSheetPresented.toggle()
            }
        } label: {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 11))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(hasGitIgnore ? PluginGitIgnoreLocalization.string("View .gitignore file") : PluginGitIgnoreLocalization.string("No .gitignore file found"))
        .disabled(projectURL == nil)
        .sheet(isPresented: $isSheetPresented) {
            GitIgnoreViewer()
                .frame(minWidth: 800, minHeight: 600)
        }
        .onAppear(perform: checkGitIgnoreExistence)
        .onChange(of: projectURL) {
            checkGitIgnoreExistence()
        }
    }

    private func checkGitIgnoreExistence() {
        guard let projectURL else {
            hasGitIgnore = false
            return
        }

        hasGitIgnore = GitIgnoreDocument.exists(in: projectURL)
    }
}
