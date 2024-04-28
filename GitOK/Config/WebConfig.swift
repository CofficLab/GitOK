import CloudKit
import OSLog
import SwiftData
import SwiftUI
import WebKit

class WebConfig: ObservableObject {    
    var view: WebView
    
    init() {
        self.view = Self.makeView()
    }

    static func makeView() -> WebView {
        #if DEBUG && false
        let view = WebView(
                .url(URL(string: "http://127.0.0.1:5173")!)
            )
        #else
        let view = WebView(
                .file(WebConfig.htmlFile)
            )
        #endif
        
        view.removeHanlders()
        view.addHanlder(ReadyHandler())
        
        return view
    }
    
    static var publicDir = Bundle.main.url(forResource: "web", withExtension: nil)

    static var htmlFile = Bundle.main.url(
        forResource: "index",
        withExtension: "html",
        subdirectory: "webview/dist"
    )!
}

#Preview("App") {
    AppPreview()
}
