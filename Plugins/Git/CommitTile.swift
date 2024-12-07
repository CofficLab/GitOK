import OSLog
import SwiftUI
import MagicKit

struct CommitTile: View, SuperEvent, SuperThread, SuperLog {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var g: GitProvider

    @State var isSynced = true
    @State var title = ""
    @State var tag = ""
    @State var isPresented: Bool = false

    var commit: GitCommit
    var project: Project
    var selected: GitCommit?

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
                    GeometryReader { geometry in
                        Text(tag)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(.gray.opacity(0.3)).clipShape(RoundedRectangle(cornerRadius: 5))
                            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .trailing)
                    }
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
        .onChange(of: selected, {
            self.ifPresented()
        })
    }

    func refreshSynced() {
        guard let branch = g.currentBranch else {
            return
        }

        self.bg.async {
            do {
                let isSynced = try commit.checkIfSynced(branch.name)

                self.main.async {
                    self.isSynced = isSynced
                }
            } catch {
                os_log(.error, "\(self.t)\(error.localizedDescription)")
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
            do {
                let tag = try commit.getTag()
                self.main.async {
                    self.tag = tag
                }
            } catch {
                os_log(.error, "\(error.localizedDescription)")
            }
        }
    }
    
    func ifPresented() {
        self.isPresented = commit.id == selected?.id
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
