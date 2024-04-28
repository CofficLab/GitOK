import CodeEditorView
import LanguageSupport
import Rearrange
import SwiftUI

struct DiffView: View {
    @EnvironmentObject var app: AppManager

    var diffBlock: DiffBlock?
    var view: WebView

    init(_ diffBlock: DiffBlock?) {
        self.diffBlock = diffBlock
        self.view = WebConfig.makeView()
    }

    var body: some View {
        Button("SSS") {
            view.content.setModified("xxxxxxxx")
        }
        
        view
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
