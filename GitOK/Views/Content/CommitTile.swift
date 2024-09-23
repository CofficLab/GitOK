import SwiftUI

struct CommitTile: View {
    @EnvironmentObject var app: AppProvider
    
    @State var isSynced = true

    var commit: GitCommit
    var project: Project

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(commit.getTitle())

                Spacer()

                if isSynced == false {
                    Image(systemName: "arrowshape.up")
                        .opacity(0.8)
                }
            }
        }
        .onAppear {
            Task.detached(operation: {
                let isSynced = try! commit.checkIfSynced()

                DispatchQueue.main.async {
                    self.isSynced = isSynced
                }
            })
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
