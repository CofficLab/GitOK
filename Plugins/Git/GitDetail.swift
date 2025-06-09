import AppKit
import MagicCore
import OSLog
import SwiftUI

struct GitDetail: View, SuperEvent, SuperLog {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var data: DataProvider
    @EnvironmentObject var m: MessageProvider

    @State var diffView: AnyView = AnyView(EmptyView())
    @State var file: File?
    @State private var isProjectClean: Bool = true

    static let shared = GitDetail()

    private var verbose = false

    private init() {
        if verbose {
            os_log("\(Self.onInit)")
        }
    }

    var body: some View {
        ZStack {
            if let project = data.project {
                if project.isGit {
                    if let commit = data.commit {
                        Group {
                            if commit.isHead && isProjectClean {
                                NoLocalChanges()
                            } else {
                                CommitDetail()
                            }
                        }
                    } else {
                        NoCommit()
                    }
                } else {
                    NoGitProjectView()
                }
            }
        }
        .onAppear(perform: onAppear)
        .onChange(of: file, onFileChange)
        .onChange(of: data.project, onProjectChange)
        .onNotification(.gitCommitSuccess, perform: onGitCommitSuccess)
        .onNotification(.appWillBecomeActive, perform: onAppWillBecomeActive)
    }
}

// MARK: - Action

extension GitDetail {
    func updateIsProjectClean() {
        self.isProjectClean = data.project?.isClean ?? true
    }
}

// MARK: Event

extension GitDetail {
    func onAppear() {
        self.updateIsProjectClean()
    }

    func onProjectChange() {
        self.updateIsProjectClean()
    }

    func onFileChange() {
        self.data.setFile(file)

        self.updateIsProjectClean()

        if let commit = data.commit, let file = file, let project = data.project {
            do {
                let v = try GitShell.diffFileFromCommit(path: project.path, hash: commit.hash, file: file.name)
                self.diffView = AnyView(v)
            } catch {
                m.error(error)
            }
        }
    }

    func onGitCommitSuccess(_ notification: Notification) {
        self.updateIsProjectClean()
        self.m.toast("已提交")
    }

    func onAppWillBecomeActive(_ n: Notification) {
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
