import SwiftUI

struct CommitTile: View, SuperEvent, SuperThread {
    @EnvironmentObject var app: AppProvider
    
    @State var isSynced = true
    @State var title = ""

    var commit: GitCommit
    var project: Project

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)

                Spacer()

                if isSynced == false {
                    Image(systemName: "arrowshape.up")
                        .opacity(0.8)
                }
            }
        }
        .onAppear() {
            self.title = commit.getTitle()
            self.bg.async {
                let isSynced = try! commit.checkIfSynced()

                self.main.async {
                    self.isSynced = isSynced
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .gitCommitSuccess)) {_ in 
            self.title = commit.getTitle()
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
