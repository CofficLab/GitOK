import GitOKCoreKit
import SwiftUI

struct ReadmeStatusIcon: View {
    let projectURL: URL

    @State private var isSheetPresented = false
    @State private var hasReadme = false

    public init(projectURL: URL) {
        self.projectURL = projectURL
    }

    var body: some View {
        Button {
            if hasReadme {
                isSheetPresented.toggle()
            }
        } label: {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 11))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(hasReadme ? PluginReadmeLocalization.string("View README.md document") : PluginReadmeLocalization.string("README.md file not found"))
        .sheet(isPresented: $isSheetPresented) {
            ReadmeViewer(projectURL: projectURL)
                .frame(minWidth: 800, minHeight: 600)
        }
        .onAppear(perform: checkReadmeExistence)
    }

    private func checkReadmeExistence() {
        hasReadme = (try? ProjectDocumentResolver.readReadmeContent(in: projectURL)) != nil
    }
}
