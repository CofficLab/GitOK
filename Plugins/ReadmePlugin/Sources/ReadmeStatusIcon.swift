import GitOKCoreKit
import ProjectSupportKit
import SwiftUI

struct ReadmeStatusIcon: View {
    let projectURL: URL

    @State private var isSheetPresented = false
    @State private var hasReadme = false

    public init(projectURL: URL) {
        self.projectURL = projectURL
    }

    var body: some View {
        AppStatusBarTile(systemImage: "doc.text.magnifyingglass", action: {
            if hasReadme {
                isSheetPresented.toggle()
            }
        })
        .help(hasReadme ? ReadmePluginLocalization.string("View README.md document") : ReadmePluginLocalization.string("README.md file not found"))
        .sheet(isPresented: $isSheetPresented) {
            ReadmeViewer(projectURL: projectURL)
                .frame(minWidth: 800, minHeight: 600)
        }
        .onAppear(perform: checkReadmeExistence)
    }

    private func checkReadmeExistence() {
        Task {
            hasReadme = await ProjectDocumentResolver.hasReadmeAsync(in: projectURL)
        }
    }
}
