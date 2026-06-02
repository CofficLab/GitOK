import SwiftUI

struct GitIgnoreStatusIcon: View {
    let projectURL: URL

    @State private var isSheetPresented = false
    @State private var hasGitIgnore = false

    public init(projectURL: URL) {
        self.projectURL = projectURL
    }

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
        .help(hasGitIgnore ? GitIgnorePluginLocalization.string("View .gitignore file") : GitIgnorePluginLocalization.string("No .gitignore file found"))
        .sheet(isPresented: $isSheetPresented) {
            GitIgnoreViewer(projectURL: projectURL)
                .frame(minWidth: 800, minHeight: 600)
        }
        .onAppear(perform: checkGitIgnoreExistence)
    }

    private func checkGitIgnoreExistence() {
        hasGitIgnore = GitIgnoreDocument.exists(in: projectURL)
    }
}
