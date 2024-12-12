import SwiftUI

struct GitDetail: View {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var g: GitProvider
    @EnvironmentObject var m: MessageProvider
    
    @State var diffView: AnyView = AnyView(EmptyView())

    var body: some View {
        ZStack {
            if let project = g.project {
                if let commit = g.commit {
                    if commit.isHead, project.isClean {
                        noLocalChangesView
                    } else {
                        HSplitView {
                            FileList()
                                .frame(idealWidth: 200)
                                .frame(minWidth: 200, maxWidth: 300)
                                .layoutPriority(1)

                            diffView
                                .frame(minWidth: 400, maxWidth: .infinity)
                                .layoutPriority(2)
                        }
                    }
                } else {
                    commitNotSelectedView
                }
            }
        }
        .onChange(of: g.file) {
            if let commit = g.commit, let file = g.file, let project = g.project {
                do {
                    let v = try g.git.diffFileFromCommit(path: project.path, hash: commit.hash, file: file.name)
                    self.diffView = AnyView(v)
                } catch {
                    m.error(error)
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
}

#Preview {
    AppPreview()
        .frame(height: 800)
        .frame(width: 800)
}
