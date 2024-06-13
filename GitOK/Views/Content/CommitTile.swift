import SwiftUI

struct CommitTile: View {
    @EnvironmentObject var app: AppManager
    
    @State var isPresented: Bool = false
    @State var isSynced = true

    var commit: GitCommit
    var project: Project
    var selection: GitCommit

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
        .navigationDestination(isPresented: $isPresented, destination: {
            CommitDetail(commit: commit)
        })
        .onAppear {
            Task.detached(operation: {
                let isSynced = try! await commit.checkIfSynced()

                DispatchQueue.main.async {
                    self.isSynced = isSynced
                }
            })
            
            ifPresented()
        }
        .onChange(of: selection, {
            ifPresented()
        })
    }
    
    func ifPresented() {
        self.isPresented = commit.id == selection.id
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
