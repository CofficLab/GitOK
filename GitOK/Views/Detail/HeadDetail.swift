import CodeEditorView
import LanguageSupport
import Rearrange
import SwiftUI

struct HeadDetail: View {
    @EnvironmentObject var app: AppManager

    @State var message = ""
    @State var diff = ""
    @State var diffBlock: DiffBlock? = nil
    @State var files: [File] = []
    @State var file: File?
    @State var codeMessages: Set<TextLocated<Message>> = Set()

    @State private var text: String = "My awesome code..."
    @State private var position: CodeEditor.Position = CodeEditor.Position()
    @State private var messages: Set<TextLocated<Message>> = Set()
    @Environment(\.colorScheme) private var colorScheme: ColorScheme

    var project: Project

    init(_ item: Project) {
        project = item
    }

    var body: some View {
        VStack {
            MergeForm(message: $message, project: project)

            CommitForm(message: $message, project: project)

            Spacer()

            if files.isEmpty {
                NoChanges()
            } else {
                FileList(file: $file, files: files)
                DiffView(diffBlock)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .onAppear {
            refreshAll()
            EventManager().onCommitted(refreshFiles)
        }
        .onChange(of: project, refreshAll)
        .onChange(of: file, {
            if let f = file {
                self.diffBlock = try! Git.diffOfFile(project.path, file: f)
                self.text = diffBlock?.block ?? ""
            }
        })
    }

    func refreshAll() {
        refreshFiles()
        refreshStatus()
        diff = try! Git.diff(project.path)
    }

    func refreshFiles() {
        files = try! Git.changedFile(project.path)

        if files.isEmpty {
            refreshStatus()
        }
    }

    func refreshStatus() {
        message = try! Git.status(project.path)
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
