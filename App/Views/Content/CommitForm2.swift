import SwiftUI

struct CommitForm2: View {
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
            VStack {
                HStack {
                    CommitCategoryPicker(selection: $category, project: project)
                        .onChange(of: category, {
                            self.text = category.defaultMessage
                        })

                    BtnCommitAndPush(repoPath: project.path, commitMessage: commitMessage)
                }

                TextField("commit", text: $text)
                    .textFieldStyle(.roundedBorder)
                    .onAppear {
                        self.text = self.category.defaultMessage
                    }
                    .padding(.vertical)
            }
            .onReceive(NotificationCenter.default.publisher(for: .gitCommitSuccess)) { _ in
                self.text = self.category.defaultMessage
            }
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 1000)
}
