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

            Text("No local changes")
                .font(.headline)
                .padding()

            Text("所有更改都已提交到本地仓库")
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

            Text("选择一个 Commit")
                .font(.headline)
                .padding()

            Text("在左侧列表中选择一个提交记录来查看详情")
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

                    ZStack {
                        if let file = g.file {
                            FileDetail(file: file, commit: commit)
                        } else {
                            Spacer()
                        }
                    }
                    .layoutPriority(3)
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
