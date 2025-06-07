import CloudKit
import MagicCore
import OSLog
import SwiftData
import SwiftUI
import WebKit

class WebConfig: ObservableObject {
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

#Preview("Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
