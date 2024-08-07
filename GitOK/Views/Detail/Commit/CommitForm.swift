import SwiftUI

struct CommitForm: View {
    @EnvironmentObject var app: AppProvider

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
                VStack {
                    HStack {
                        CommitCategoryPicker(selection: $category, project: project)
                            .onChange(of: category, {
                                self.text = category.defaultMessage
                            })
                        
                        TextField("commit", text: $text)
                            .textFieldStyle(.roundedBorder)
                            .onAppear() {
                                self.text = self.category.defaultMessage
                            }
                        
                        BtnCommit(path: project.path, commit: commitMessage)
                    }
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
