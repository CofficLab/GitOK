import CodeEditorView
import LanguageSupport
import Rearrange
import SwiftUI

struct DiffView: View {
    @EnvironmentObject var app: AppManager

    var diffBlock: DiffBlock?
    @State var codeMessages: Set<TextLocated<Message>> = Set()

    @State private var position: CodeEditor.Position = CodeEditor.Position()
    @State private var messages: Set<TextLocated<Message>> = Set()
    @Environment(\.colorScheme) private var colorScheme: ColorScheme

    init(_ diffBlock: DiffBlock?) {
        self.diffBlock = diffBlock
    }

    var body: some View {
        CodeEditor(
            text: .constant(diffBlock?.block ?? ""),
            position: $position,
            messages: $messages,
            language: .swift(),
            layout: .init(showMinimap: false, wrapText: true))
            .environment(\.codeEditorTheme,
                         colorScheme == .dark ? Theme.defaultDark : Theme.defaultLight)
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
