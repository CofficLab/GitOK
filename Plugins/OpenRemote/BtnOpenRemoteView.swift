import SwiftUI

struct BtnOpenRemoteView: View {
    @EnvironmentObject var g: DataProvider
    @State private var remoteURL: URL?
    @State private var isLoading = false
    
     static let shared = BtnOpenRemoteView()
     
     private init() {}
    
    var body: some View {
        ZStack {
            if let url = remoteURL {
                url.makeOpenButton().magicShapeVisibility(.onHover)
            } else if isLoading {
                // 添加加载指示器或占位符
                Color.clear.frame(width: 24, height: 24)
            } else {
                // 空状态占位符，确保视图始终有内容
                Color.clear.frame(width: 24, height: 24)
            }
        }
        .onAppear {
            updateRemoteURL()
        }
        .onChange(of: g.project) {
            updateRemoteURL()
        }
    }
    
    func updateRemoteURL() {
        guard let project = g.project, project.isGit else {
            remoteURL = nil
            return
        }
        
        isLoading = true
        
//        DispatchQueue.global(qos: .userInitiated).async {
//            let remote = try g.project?.getFirstRemote() ?? ""
//            
//            var formattedRemote = remote
//            if formattedRemote.hasPrefix("git@") {
//                formattedRemote = formattedRemote.replacingOccurrences(of: ":", with: "/")
//                formattedRemote = formattedRemote.replacingOccurrences(of: "git@", with: "https://")
//            }
//            
//            DispatchQueue.main.async {
//                if !formattedRemote.isEmpty {
//                    remoteURL = URL(string: formattedRemote)
//                } else {
//                    remoteURL = nil
//                }
//                isLoading = false
//            }
//        }
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
