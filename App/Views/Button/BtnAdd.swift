import SwiftUI
import OSLog

struct BtnAdd: View {
    @EnvironmentObject var g: GitProvider
    @EnvironmentObject var repoManager: RepoManager
    
    var body: some View {
        Button(action: open) {
            Label("Open Item", systemImage: "plus")
        }
    }
    
    private func open() {
        os_log("open")
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        if panel.runModal() == .OK, let url = panel.url {
            addURL(url)
        } else {
        }
    }
    
    private func addURL(_ url: URL) {
        withAnimation {
            g.addProject(url: url, using: repoManager.projectRepo)
        }
    }
}

#Preview {
    AppPreview()
}

#Preview("App-Big Screen") {
    RootView {
        ContentView()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
