import SwiftUI
import OSLog

struct DiffView: View {
    @EnvironmentObject var app: AppManager
    @EnvironmentObject var webConfig: WebConfig

    var file: File?
    var view: WebView { webConfig.view }

    init(_ file: File?) {
        self.file = file
    }

    var body: some View {
        view
            .frame(maxWidth: .infinity)
            .onAppear {
            EventManager().onJSReady {
                view.content.setOriginal(file?.lastContent ?? "")
                view.content.setModified(file?.content ?? "")
            }
        }
        .onChange(of: file, {
            view.content.setOriginal(file?.lastContent ?? "")
            view.content.setModified(file?.content ?? "")
        })
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
