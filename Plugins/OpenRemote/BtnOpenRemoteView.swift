import MagicKit
import OSLog
import SwiftUI

struct BtnOpenRemoteView: View, SuperLog {
    @EnvironmentObject var g: DataProvider

    @State private var webURL: URL?
    @State private var isLoading = false
    @State private var isGitProject: Bool = true

    static let shared = BtnOpenRemoteView()
    static let emoji = "💊"

    private var verbose = false

    private init() {}

    var body: some View {
        ZStack {
            if let url = webURL {
                Image.safariApp
                    .resizable()
                    .frame(height: 22)
                    .frame(width: 22)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 5)
                    .hoverBackground(.regularMaterial)
                    .inButtonWithAction {
                        url.openInSafari()
                    }
            } else if isLoading {
                // 添加加载指示器或占位符
                Color.clear.frame(width: 24, height: 24)
            } else {
                // 空状态占位符，确保视图始终有内容
                Color.clear.frame(width: 24, height: 24)
            }
        }
        .onAppear(perform: onAppear)
        .onChange(of: g.project?.url, onProjectChange)
        .help("在浏览器打开")
    }
}

// MARK: - Action

extension BtnOpenRemoteView {
    func updateRemoteURL() {
        guard let project = g.project, self.isGitProject else {
            webURL = nil
            return
        }

        isLoading = true

        do {
            let remotes = try project.remoteList()
            var remoteURL: String?

            for remote in remotes {
                if remote.name == "origin" {
                    remoteURL = remote.url
                    break
                }
            }

            if verbose {
                os_log(.info, "\(self.t)🔄 Update remoteURL: \(remoteURL ?? "")")
            }

            var formattedRemote = remoteURL ?? ""
            if formattedRemote.hasPrefix("git@") {
                formattedRemote = formattedRemote.replacingOccurrences(of: ":", with: "/")
                formattedRemote = formattedRemote.replacingOccurrences(of: "git@", with: "https://")
            }

            DispatchQueue.main.async {
                if !formattedRemote.isEmpty {
                    self.webURL = URL(string: formattedRemote)
                } else {
                    self.webURL = nil
                }
                isLoading = false
            }
        } catch {
            os_log(.error, "\(self.t)\(error.localizedDescription)")
        }
    }

    func updateIsGitProject() {
        guard let project = g.project else {
            return
        }

        self.isGitProject = project.isGitRepo
    }
    
    /**
        异步更新Git项目状态
        
        使用异步方式避免阻塞主线程，解决CPU占用100%的问题
     */
    func updateIsGitProjectAsync() async {
        guard let project = g.project else {
            await MainActor.run {
                self.isGitProject = false
            }
            return
        }
        
        let isGit = await project.isGitAsync()
        await MainActor.run {
            self.isGitProject = isGit
        }
    }
}

// MARK: - Event

extension BtnOpenRemoteView {
    func onAppear() {
        Task {
            await self.updateIsGitProjectAsync()
            self.updateRemoteURL()
        }
    }

    func onProjectChange() {
        Task {
            await self.updateIsGitProjectAsync()
            self.updateRemoteURL()
        }
    }
}

// MARK: - Preview

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
