import SwiftUI
import OSLog

struct DiffView: View {
    @EnvironmentObject var app: AppManager
    @EnvironmentObject var webConfig: WebConfig

    var file: File? { app.file }
    var view: WebView { webConfig.view }

    var body: some View {
        if let file = file {
            view
                .frame(maxWidth: .infinity)
                .onAppear {
                EventManager().onJSReady {
                    refresh()
                }
            }
            .onChange(of: file, refresh)
        }
    }
    
    func refresh() {
        guard let file = file else {
            return
        }
        
        view.content.setOriginal(file.lastContent)
        view.content.setModified(file.content)
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
