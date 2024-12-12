import MagicKit
import SwiftUI

struct CommitList: View, SuperThread, SuperLog {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var g: GitProvider

    @State private var commits: [GitCommit] = []
    @State private var loading = false
    @State private var selection: GitCommit?
    @State private var showCommitForm = false
    @State private var isRefreshing = false
    @State private var hasMoreCommits = true
    @State private var currentPage = 0
    @State private var pageSize: Int = 50

    var emoji = "🖥️"
    var verbose = true

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                if loading && commits.isEmpty {
                    Spacer()
                    Text(LocalizedStringKey("loading"))
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0, pinnedViews: []) {
                            Divider()

                            ForEach(commits) { commit in
                                CommitRow(commit: commit,
                                          isSelected: selection == commit,
                                          onSelect: { selectCommit(commit) })
                                    .id(commit.id)
                                    .onAppear {
                                        let index = commits.firstIndex(of: commit) ?? 0
                                        let threshold = Int(Double(commits.count) * 0.8)
                                        if index >= threshold && hasMoreCommits && !loading {
                                            loadMoreCommits()
                                        }
                                    }
                            }

                            if loading && !commits.isEmpty {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                    Spacer()
                                }
                                .frame(height: 44)

                                Divider()
                            }
                        }
                    }
                    .background(Color(.controlBackgroundColor))

                    CommitForm()
                        .padding(.horizontal, 4)
                        .padding(.vertical, 6)
                        .background(BackgroundView.type2.opacity(0.1))
                }
            }
            .onAppear {
                let rowHeight: CGFloat = 31
                let visibleRows = Int(ceil(geometry.size.height / rowHeight))
                pageSize = max(self.pageSize, visibleRows + 5)
                onAppear()
            }
        }
        .onAppear(perform: onAppear)
        .onChange(of: selection, onChangeOfSelection)
        .onChange(of: g.project, onProjectChange)
        .onReceive(NotificationCenter.default.publisher(for: .gitCommitSuccess), perform: onCommitSuccess)
        .onReceive(NotificationCenter.default.publisher(for: .gitPullSuccess), perform: onPullSuccess)
        .onReceive(NotificationCenter.default.publisher(for: .gitPushSuccess), perform: onPushSuccess)
    }

    private func loadMoreCommits() {
        guard let project = g.project, !loading, hasMoreCommits else { return }

        loading = true

        bg.async {
            do {
                let newCommits = try GitShell().logsWithPagination(
                    project.path,
                    skip: currentPage * pageSize,
                    limit: pageSize
                )

                main.async {
                    if !newCommits.isEmpty {
                        commits.append(contentsOf: newCommits)
                        currentPage += 1
                    } else {
                        hasMoreCommits = false
                    }
                    loading = false
                }
            } catch {
                main.async {
                    loading = false
                }
            }
        }
    }

    func refresh(_ reason: String = "") {
        guard let project = g.project, !isRefreshing else { return }

        isRefreshing = true
        loading = true

        currentPage = 0
        hasMoreCommits = true

        bg.async {
            do {
                let initialCommits = try GitShell().logsWithPagination(
                    project.path,
                    skip: 0,
                    limit: pageSize
                )

                main.async {
                    commits = [project.headCommit] + initialCommits
                    loading = false
                    isRefreshing = false
                    currentPage = 1

                    let hasChanges = project.hasUnCommittedChanges()
                    showCommitForm = hasChanges
                }
            } catch {
                main.async {
                    loading = false
                    isRefreshing = false
                }
            }
        }
    }

    private func selectCommit(_ commit: GitCommit) {
        selection = commit
        g.setCommit(commit)
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

// MARK: CommitRow

private struct CommitRow: View {
    let commit: GitCommit
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onSelect) {
                HStack {
                    Text(commit.message)
                        .lineLimit(1)
                        .font(.system(size: 13))
                    Spacer()
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .frame(height: 25)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)

            Divider()
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
