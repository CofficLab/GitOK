import AppKit
import MagicCore
import MagicAlert
import MagicBackground
import OSLog
import SwiftUI

struct GitDetail: View, SuperEvent, SuperLog {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var data: DataProvider
    @EnvironmentObject var m: MagicMessageProvider

    @State private var isProjectClean: Bool = true
    @State private var isGitProject: Bool = false

    static let shared = GitDetail()

    private var verbose = false

    private init() {
        if verbose {
            os_log("\(Self.onInit)")
        }
    }

    var body: some View {
        ZStack {
            if data.project != nil {
                if self.isGitProject {
                    VStack(alignment: .leading, spacing: 8) {
                        Group {
                            if let commit = data.commit {
                                CommitInfoView(commit: commit)
                            } else if self.isProjectClean == false {
                                CommitForm()
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)

                        if !self.isProjectClean || self.data.commit != nil {
                            HSplitView {
                                FileList()
                                    .frame(idealWidth: 200)
                                    .frame(minWidth: 200, maxWidth: 300)
                                    .layoutPriority(1)

                                FileDetail()
                            }
                            .padding(.horizontal, 0)
                            .padding(.vertical, 0)
                        } else {
                            NoLocalChanges()
                        }
                    }
                } else {
                    NoGitProjectView()
                }
            }
        }
        .onAppear(perform: onAppear)
        .onChange(of: data.project, onProjectChange)
        .onProjectDidCommit(perform: onGitCommitSuccess)
        .onNotification(.appWillBecomeActive, perform: onAppWillBecomeActive)
    }

    private var background: some View {
        ZStack {
            if data.commit == nil {
                MagicBackground.orange.opacity(0.15)
            } else {
                MagicBackground.colorGreen.opacity(0.15)
            }
        }
    }
}

// MARK: - Action

extension GitDetail {
    func updateIsProjectClean() {
        guard let project = data.project else {
            return
        }

        do {
            self.isProjectClean = try project.isClean()
        } catch {
            os_log(.error, "\(self.t)❌ Failed to update isProjectClean: \(error)")
        }

        if verbose {
            os_log(.info, "\(self.t)🔄 Update isProjectClean: \(self.isProjectClean)")
        }
    }

    func updateIsGitProject() {
        guard let project = data.project else {
            return
        }

        self.isGitProject = project.isGit()
    }
    
    /**
        异步更新Git项目状态
        
        使用异步方式避免阻塞主线程，解决CPU占用100%的问题
     */
    func updateIsGitProjectAsync() async {
        guard let project = data.project else {
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

// MARK: Event

extension GitDetail {
    func onAppWillBecomeActive(_ notification: Notification) {
        self.updateIsProjectClean()
    }

    func onAppear() {
        Task {
            await self.updateIsGitProjectAsync()
            self.updateIsProjectClean()
        }
    }

    func onProjectChange() {
        self.updateIsProjectClean()
    }

    func onGitCommitSuccess(_ eventInfo: ProjectEventInfo) {
        self.updateIsProjectClean()
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideTabPicker()
            .hideProjectActions()
    }
    .frame(width: 600)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
