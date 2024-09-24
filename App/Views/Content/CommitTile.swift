import SwiftUI

struct CommitTile: View, SuperEvent, SuperThread {
    @EnvironmentObject var app: AppProvider

    @State var isSynced = true
    @State var title = ""
    @State var tag = ""

    var commit: GitCommit
    var project: Project

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HStack {
                    if commit.isHead {
                        Image(systemName: "arrowshape.right")
                    }
                    Text(title)
                }

                Spacer()

                if isSynced == false {
                    Image(systemName: "arrowshape.up")
                        .opacity(0.8)
                }

                if tag.isNotEmpty && commit.isHead == false {
                    Text(tag)
                        .padding(3)
                        .background(RoundedRectangle(cornerRadius: 5).fill(Color.gray.opacity(0.2)))
                }
            }
        }
        .onAppear {
            self.refreshTitle()
            self.refreshSynced()
            self.refreshTag()
        }
        .onReceive(NotificationCenter.default.publisher(for: .gitCommitSuccess)) { _ in
            self.refreshTitle()
        }
    }

    func refreshSynced() {
        self.bg.async {
            let isSynced = try! commit.checkIfSynced()

            self.main.async {
                self.isSynced = isSynced
            }
        }
    }

    func refreshTitle() {
        self.bg.async {
            let title = commit.getTitle(reason: "CommitTile.RefreshTitle")
            self.main.async {
                self.title = title
            }
        }
    }

    func refreshTag() {
        self.bg.async {
            let tag = commit.getTag()
            self.main.async {
                self.tag = tag
            }
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
