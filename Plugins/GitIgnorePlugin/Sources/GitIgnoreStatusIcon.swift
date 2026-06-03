import GitOKCoreKit
import SwiftUI

struct GitIgnoreStatusIcon: View {
    let projectURL: URL

    @State private var isSheetPresented = false
    @State private var hasGitIgnore = false

    public init(projectURL: URL) {
        self.projectURL = projectURL
    }

    var body: some View {
        AppStatusBarTile(systemImage: "doc.text.fill", action: {
            if hasGitIgnore {
                isSheetPresented.toggle()
            }
        })
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
