import AppKit
import MagicCore
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
                            } else {
                                CommitForm()
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)

                        HSplitView {
                            FileList()
                                .frame(idealWidth: 200)
                                .frame(minWidth: 200, maxWidth: 300)
                                .layoutPriority(1)

                            FileDetail()
                        }
                    }
                    .padding(.horizontal, 0)
                    .padding(.vertical, 0)
                    .background(background)
                } else {
                    NoGitProjectView()
                }
            }
        }
        .onAppear(perform: onAppear)
        .onChange(of: data.project, onProjectChange)
        .onNotification(.projectDidCommit, perform: onGitCommitSuccess)
        .onNotification(.appWillBecomeActive, perform: onAppWillBecomeActive)
        .onChange(of: data.project) { self.onProjectChanged() }
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
        self.isProjectClean = data.project?.isClean() ?? true
    }
    
    func updateIsGitProject() {
        self.isGitProject = data.project?.isGit() ?? false
    }
}

// MARK: Event

extension GitDetail {
    func onAppWillBecomeActive(_ notification: Notification) {
    }

    func onProjectChanged() {
    }

    func onAppear() {
        self.updateIsProjectClean()
        self.updateIsGitProject()
    }

    func onProjectChange() {
        self.updateIsProjectClean()
    }

    func onGitCommitSuccess(_ notification: Notification) {
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
