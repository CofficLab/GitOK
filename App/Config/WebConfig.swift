import CloudKit
import OSLog
import SwiftData
import SwiftUI
import MagicCore
import WebKit
import MagicWeb

class WebConfig: ObservableObject {    
    var view: MagicWeb.WebView
    
    init() {
        self.view = Self.makeView()
    }

    static func makeView() -> MagicWeb.WebView {
        #if DEBUG && false
        let view = WebView(
                .url(URL(string: "http://127.0.0.1:5173")!)
            )
        #else
        let view = MagicWeb.WebView(htmlFile: WebConfig.htmlFile, config: Self.getViewConfig())
        #endif
        
        return view
    }
    
    static var publicDir = Bundle.main.url(forResource: "web", withExtension: nil)

    static var htmlFile = Bundle.main.url(
        forResource: "index",
        withExtension: "html",
        subdirectory: "webview/dist"
    )!
    
    static func getViewConfig() -> WKWebViewConfiguration {
        let userContentController = WKUserContentController()
        let config = WKWebViewConfiguration()

        config.userContentController = userContentController
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")

        return config
    }
}

#Preview("App") {
    AppPreview()
}
