import OSLog
import SwiftUI

struct DiffView: View {
    @EnvironmentObject var app: AppManager
    @EnvironmentObject var webConfig: WebConfig

    var file: File? { app.file }
    var view: WebView { webConfig.view }
    var commit: GitCommit
    var label: String { "\(Logger.isMain)🍺 DiffView::" }

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
                    .onChange(of: commit, refresh)
            }
        } else {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("选择一个文件以查看变动")
                    Spacer()
                }
            }
        }
    }

    func refresh() {
        guard let file = file else {
            return
        }

        os_log("\(self.label)Refresh")
        if commit.isHead {
            view.content.setTexts(file.lastContent, file.content)
        } else {
            view.content.setTexts(file.originalContentOfCommit(commit), file.contentOfCommit(commit))
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
