import SwiftUI

struct BtnOpenRemoteView: View {
    @EnvironmentObject var g: DataProvider
    
    static let shared = BtnOpenRemoteView()
    
    private init() {}

    var body: some View {
        if let url = getURL() {
            url.makeOpenButton().magicShapeVisibility(.onHover).magicShape(.roundedSquare)
        }
    }
    
    private func getURL() -> URL? {
        guard let project = g.project, project.isGit else {
            return nil
        }
        
        var remote = GitShell.getRemote(project.path).trimmingCharacters(in: .whitespacesAndNewlines)

        if remote.hasPrefix("git@") {
            remote = remote.replacingOccurrences(of: ":", with: "/")
            remote = remote.replacingOccurrences(of: "git@", with: "https://")
        }

        return URL(string: remote)
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 600)
    .frame(height: 600)
}

#Preview("App-Big Screen") {
    RootView {
        ContentLayout()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}

