import SwiftUI

struct LogTile: View {
    @EnvironmentObject var app: AppManager

    @State var isSynced = true

    var commit: GitCommit
    var project: Project
    var branch: Branch

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(commit.message)

                Spacer()

                if isSynced == false {
                    Image(systemName: "arrowshape.up")
                        .opacity(0.8)
                }
            }
        }
        .onAppear {
            Task.detached(operation: {
                let isSynced = await commit.checkIfSynced()

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
