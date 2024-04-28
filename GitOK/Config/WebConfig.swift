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
        #if DEBUG && true
            var view = WebView(
                .url(URL(string: "http://127.0.0.1:5173")!)
            )
        #else
            var view = WebView(
                .file(WebConfig.htmlFile)
            )
        #endif
        
        view.controller.add(WebAgent(), name: "sendMessage")
        
        return view
    }
    
    static var publicDir = Bundle.main.url(forResource: "web", withExtension: nil)

    static var htmlFile = Bundle.main.url(
        forResource: "index",
        withExtension: "html",
        subdirectory: "web"
    )
}

#Preview("App") {
    AppPreview()
}
