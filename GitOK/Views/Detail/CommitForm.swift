import SwiftUI

struct CommitForm: View {
    @EnvironmentObject var app: AppManager
    
    @State var text: String = ""
    @State var category: CommitCategory = .Chore
    
    var commitMessage: String {
        var c = text
        if c.isEmpty {
            c = "Auto Committed by GitOK"
        }
        
        return "\(category.text) \(c)"
    }

    var body: some View {
        if let project = app.project {
            Group {
                HStack {
                    CommitCategoryPicker(selection: $category, project: project)
                    TextField("commit", text: $text)
                        .textFieldStyle(.roundedBorder)
                    BtnCommit(path: project.path, commit: commitMessage)
                }
            }
            .onAppear(perform: {
                EventManager().onCommitted {
                    self.text = ""
                }
            })
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 500)
}
