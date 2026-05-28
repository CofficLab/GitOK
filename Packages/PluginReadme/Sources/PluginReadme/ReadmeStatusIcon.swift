import GitOKPluginKit
import ProjectSupportKit
import SwiftUI

struct ReadmeStatusIcon: View {
    @Environment(\.gitOKProjectURL) private var projectURL

    @State private var isSheetPresented = false
    @State private var hasReadme = false

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
        .disabled(projectURL == nil)
        .sheet(isPresented: $isSheetPresented) {
            ReadmeViewer()
                .frame(minWidth: 800, minHeight: 600)
        }
        .onAppear(perform: checkReadmeExistence)
        .onChange(of: projectURL) {
            checkReadmeExistence()
        }
    }

    private func checkReadmeExistence() {
        guard let projectURL else {
            hasReadme = false
            return
        }

        hasReadme = (try? ProjectDocumentResolver.readReadmeContent(in: projectURL)) != nil
    }
}
