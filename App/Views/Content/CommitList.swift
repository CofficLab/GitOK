import MagicKit
import OSLog
import SwiftUI

struct CommitList: View, SuperThread, SuperLog {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var g: GitProvider

    @State var commits: [GitCommit] = []
    @State var loading = false
    @State var selection: GitCommit?
    @State var showCommitForm = false
    @State private var isRefreshing = false

    var emoji = "🖥️"
    var verbose = true

    var body: some View {
        if let project = g.project {
            VStack(spacing: 0) {
                if loading {
                    Spacer()
                    Text("loading...")
                    Spacer()
                } else {
                    List(commits, selection: self.$selection) { commit in
                        CommitTile(commit: commit, project: project, selected: selection).tag(commit)
                    }

//                    if showCommitForm {
                        GroupBox {
                            CommitForm()
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 6)
                        .background(BackgroundView.type2.opacity(0.1))
//                    }
                }
            }
            .onAppear(perform: onAppear)
            .onChange(of: selection, onChangeOfSelection)
            .onChange(of: g.project, onProjectChange)
            .onReceive(NotificationCenter.default.publisher(for: .gitCommitSuccess), perform: onCommitSuccess)
            .onReceive(NotificationCenter.default.publisher(for: .gitPullSuccess), perform: onPullSuccess)
            .onReceive(NotificationCenter.default.publisher(for: .gitPushSuccess), perform: onPushSuccess)
//            .onReceive(NotificationCenter.default.publisher(for: .appWillBecomeActive), perform: onAppWillBecomeActive)
        }
    }

    func refresh(_ reason: String = "") {
        let verbose = false

        guard let project = g.project, !isRefreshing else {
            return
        }

        isRefreshing = true

        self.loading = true

        self.bg.async {
            if verbose {
                os_log("\(t)Refresh(\(reason))")
            }

            let commits = [project.headCommit] + project.getCommits(reason)

            self.main.async {
                self.commits = commits
                self.loading = false
                self.isRefreshing = false
                self.showCommitForm = project.hasUnCommittedChanges()
            }
        }
    }
}

// MARK: Event Handlers

extension CommitList {
    func onProjectChange() {
        self.refresh("\(self.t)Project Changed")
    }

    func onCommitSuccess(_ notification: Notification) {
        self.refresh("\(self.t)GitCommitSuccess")
    }

    func onAppear() {
        refresh("OnAppear")
    }

    func onChangeOfSelection() {
        g.setCommit(selection)
    }

    func onPullSuccess(_ notification: Notification) {
        self.refresh("\(self.t)GitPullSuccess")
    }

    func onPushSuccess(_ notification: Notification) {
        self.refresh("\(self.t)GitPushSuccess")
    }

    func onAppWillBecomeActive(_ notification: Notification) {
        self.refresh("\(self.t)AppWillBecomeActive")
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
