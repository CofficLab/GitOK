import OSLog
import SwiftUI

struct DiffView: View {
    @EnvironmentObject var app: AppManager
    @EnvironmentObject var webConfig: WebConfig

    var file: File? { app.file }
    var view: WebView { webConfig.view }
    var commit: GitCommit

    var body: some View {
        if let file = file {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "doc.text")
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
            }
        } else {
            Text("选择一个文件以查看变动")
        }
    }

    @MainActor
    func refresh() {
        guard let file = file else {
            return
        }
        
        if commit.isHead {
            view.content.setOriginal(file.lastContent)
            view.content.setModified(file.content)
        } else {
            view.content.setOriginal(file.originalContentOfCommit(commit))
            view.content.setModified(file.contentOfCommit(commit))
        }
        
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
