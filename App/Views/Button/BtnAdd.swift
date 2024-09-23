import SwiftUI
import OSLog

struct BtnAdd: View {
    @Environment(\.modelContext) private var modelContext
    
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
            let newProject = Project(url)
            modelContext.insert(newProject)
        }
    }
}

#Preview {
    AppPreview()
}
