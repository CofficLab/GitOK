import CloudKit
import OSLog
import SwiftData
import SwiftUI
import WebKit

class WebConfig: ObservableObject {
    @AppStorage("Web.Token")
    static var token: String = ""
    
    @AppStorage("Web.Url")
    static var url: String = "https://pre.kuaiyizhi.cn"
    
    var view: WebView
    
    init() {
        self.view = Self.makeView()
    }

    static func makeView() -> WebView {
        #if DEBUG && true
            WebView(
                url: URL(string: "http://127.0.0.1:5173")
            )
        #else
            WebView(
                htmlFile: WebConfig.htmlFile
            )
        #endif
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
