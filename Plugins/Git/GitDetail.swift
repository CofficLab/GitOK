import SwiftUI
import MagicKit

struct GitDetail: View, SuperEvent {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var g: GitProvider
    @EnvironmentObject var m: MessageProvider

    @State var diffView: AnyView = AnyView(EmptyView())
    @State var file: File?
    @State private var isProjectClean: Bool = true

    var body: some View {
        ZStack {
            if let project = g.project {
                if let commit = g.commit {
                    Group {
                        if commit.isHead && isProjectClean {
                            noLocalChangesView
                        } else {
                            HSplitView {
                                FileList(file: $file, commit: commit)
                                    .frame(idealWidth: 200)
                                    .frame(minWidth: 200, maxWidth: 300)
                                    .layoutPriority(1)

                                diffView
                                    .frame(minWidth: 400, maxWidth: .infinity)
                                    .layoutPriority(2)
                            }
                        }
                    }
                } else {
                    commitNotSelectedView
                }
            }
        }
        .onAppear(perform: onAppear)
        .onChange(of: file, onFileChange)
        .onReceive(nc.publisher(for: .gitCommitSuccess), perform: onGitCommitSuccess)
    }

    var noLocalChangesView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundColor(.green)

            Text(LocalizedStringKey("no_local_changes_title"))
                .font(.headline)
                .padding()

            Text(LocalizedStringKey("no_local_changes_description"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var commitNotSelectedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text(LocalizedStringKey("select_commit_title"))
                .font(.headline)
                .padding()

            Text(LocalizedStringKey("select_commit_description"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension GitDetail {
    func onAppear() {
        isProjectClean = g.project?.isClean ?? true
    }

    func onFileChange() {
        self.g.setFile(file)

        isProjectClean = g.project?.isClean ?? true
        
        if let commit = g.commit, let file = file, let project = g.project {
            do {
                let v = try GitShell.diffFileFromCommit(path: project.path, hash: commit.hash, file: file.name)
                self.diffView = AnyView(v)
            } catch {
                m.error(error)
            }
        }
    }

    func onGitCommitSuccess(_ notification: Notification) {
        isProjectClean = g.project?.isClean ?? true
        self.m.toast("已提交")
    }
}

#Preview {
    AppPreview()
        .frame(height: 800)
        .frame(width: 800)
}
