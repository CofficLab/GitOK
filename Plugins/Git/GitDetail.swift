import AppKit
import MagicCore
import SwiftUI

struct GitDetail: View, SuperEvent {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var data: DataProvider
    @EnvironmentObject var m: MessageProvider

    @State var diffView: AnyView = AnyView(EmptyView())
    @State var file: File?
    @State private var isProjectClean: Bool = true

    var body: some View {
        ZStack {
            if let project = data.project {
                if project.isGit {
                    if let commit = data.commit {
                        Group {
                            if commit.isHead && isProjectClean {
                                NoLocalChanges()
                            } else {
                                VStack(spacing: 0) {
                                    // 当前 Commit 详细信息
                                    CommitDetailView(commit: commit)

                                    HSplitView {
                                        FileList(file: $file, commit: commit)
                                            .frame(idealWidth: 200)
                                            .frame(minWidth: 200, maxWidth: 300)
                                            .layoutPriority(1)

                                        if let file = data.file {
                                            FileDetail(file: file, commit: commit)
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        NoCommit()
                    }
                } else {
                    NoGitProjectView()
                }
            } else {
                NoProjectView()
            }
        }
        .onAppear(perform: onAppear)
        .onChange(of: file, onFileChange)
        .onChange(of: data.project, onProjectChange)
        .onReceive(nc.publisher(for: .gitCommitSuccess), perform: onGitCommitSuccess)
    }
}

// MARK: Event

extension GitDetail {
    func onAppear() {
        isProjectClean = data.project?.isClean ?? true
    }
    
    func onProjectChange() {
        isProjectClean = data.project?.isClean ?? true
    }

    func onFileChange() {
        self.data.setFile(file)

        isProjectClean = data.project?.isClean ?? true

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
        isProjectClean = data.project?.isClean ?? true
        self.m.toast("已提交")
    }
}

#Preview("默认") {
    RootView {
        ContentView()
    }
    .frame(height: 600)
    .frame(width: 600)
}

#Preview("App-Big Screen") {
    RootView {
        ContentView()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
