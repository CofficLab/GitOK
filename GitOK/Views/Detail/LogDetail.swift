import SwiftUI

struct LogDetail: View {
    @EnvironmentObject var app: AppManager
    
    @State var message = ""

    var item: Project
    var log: GitCommit

    init(_ item: Project, log: GitCommit) {
        self.item = item
        self.log = log
    }

    var body: some View {
        VStack {
            GroupBox {
                HStack {
                    Text(log.message)
                    Spacer()
                }
                
                HStack {
                    Text(log.hash)
                    Spacer()
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .onAppear {
            message = Git.status(item.path)
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
