import SwiftUI

struct FileDetail: View {
    @EnvironmentObject var webConfig: WebConfig
    
    var file: File
    var commit: GitCommit
    var view: WebView { webConfig.view }
    
    var body: some View {
        VStack(spacing: 0) {
            view
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
                .onChange(of: file, refresh)
                .onChange(of: commit, refresh)
                .onReceive(NotificationCenter.default.publisher(for: .jsReady)) { _ in
                    refresh()
                }
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
