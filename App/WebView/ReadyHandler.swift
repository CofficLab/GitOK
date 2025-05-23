import SwiftUI
import WebKit
import OSLog
import MagicCore
import MagicWeb

class ReadyHandler: NSObject, WebHandler, SuperEvent {
    var functionName: String = "ready"
    var label = "👷 ReadyHandler::"

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let verbose = false 
        if verbose {
            os_log("\(self.label)JS call \(message.name)")
        }
        emitJsReady()
    }
}

#Preview {
    AppPreview()
}
