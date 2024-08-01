import SwiftUI

struct FileDetail: View {
    @EnvironmentObject var webConfig: WebConfig
    
    var file: File
    var commit: GitCommit
    var view: WebView { webConfig.view }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "doc.text").padding(.leading)
                Text(file.name)
                    .padding(.vertical, 4)
                Spacer()
            }
            .background(Color.accentColor.opacity(0.5))
            
            view
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
                .onAppear {
                    EventManager().onJSReady {
                        refresh()
                    }
                }
                .onChange(of: file, refresh)
                .onChange(of: commit, refresh)
        }
    }
    
    func refresh() {
//        if commit.isHead {
//            view.content.setTexts(file.lastContent, file.content)
//        } else {
            view.content.setTexts(file.originalContentOfCommit(commit), file.contentOfCommit(commit))
//        }
    }
}

#Preview {
    AppPreview()
}
