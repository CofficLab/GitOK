import SwiftUI

struct Detail: View {
    @EnvironmentObject var app: AppManager

    @Binding var tab: ActionTab
    
    var project: Project? { app.project }
    var commit: GitCommit? { app.commit }

    var body: some View {
        if tab == .Banner {
            BannerHome(banner: $app.banner)
        } else if tab == .Icon {
            IconHome(icon: $app.icon)
        } else {
            if project?.isNotGit ?? false {
                NotGit()
            } else {
                GeometryReader { geo in
                    if commit?.getFiles().count == 0 {
                        VStack {
                            MergeForm().padding()
                            NoChanges().frame(maxHeight: .infinity)
                        }
                    } else {
                        VStack {
                            if commit?.isHead ?? false {
                                CommitForm().padding()
                                MergeForm().padding()
                            }

                            if let commit = commit {
                                DiffView(commit: commit)
                                    .frame(maxHeight: .infinity)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview("Detail-Banner") {
    RootView {
        Detail(tab: Binding.constant(.Banner))
    }
}

#Preview("Detail-Icon") {
    RootView {
        Detail(tab: Binding.constant(.Icon))
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
