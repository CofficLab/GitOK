import SwiftUI

struct DetailGit: View {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var g: GitProvider

    var body: some View {
        Group {
            if let project = g.project {
                if let commit = g.commit {
                    if commit.isHead, project.isClean {
                        noLocalChangesView
                    } else {
                        filesAndChangesView
                    }
                } else {
                    commitNotSelectedView
                }
            }
        }
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

    var filesAndChangesView: some View {
        VSplitView {
            if let commit = g.commit {
                HSplitView {
                    FileList()
                        .frame(minWidth: 200)
                        .layoutPriority(2)

                    Group {
                        if let project = g.project, let file = g.file {
                            try? g.git.diffFileFromCommit(path: project.path, hash: commit.hash, file: file.name)
                        } else {
                            Spacer()
                        }
                    }
                    .layoutPriority(3)

//                    Group {
//                        if let file = g.file {
//                            FileDetail(file: file, commit: commit)
//                        } else {
//                            Spacer()
//                        }
//                    }
//                    .layoutPriority(3)
                }
                .layoutPriority(6)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    AppPreview()
        .frame(height: 800)
        .frame(width: 800)
}
