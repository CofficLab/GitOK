import MagicKit
import OSLog
import SwiftUI

struct CommitForm: View, SuperLog {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var g: DataProvider

    @State var text: String = ""
    @State var category: CommitCategory = .Chore

    var commitMessage: String {
        var c = text
        if c.isEmpty {
            c = "Auto Committed by GitOK"
        }

        let includeEmoji = g.repoManager.stateRepo.commitStyleIncludeEmoji
        return "\(category.text(includeEmoji: includeEmoji)) \(c)"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                CommitCategoryPicker(
                    selection: $category
                )

                Spacer()
                TextField("commit", text: $text)
                    .textFieldStyle(.roundedBorder)
                    .padding(.vertical)
            }

            HStack {
                UserView().frame(maxWidth: 300)
                
                Spacer()

                BtnCommitAndPush(commitMessage: commitMessage, commitOnly: true)
                BtnCommitAndPush(commitMessage: commitMessage)
            }
            .frame(height: 40)
        }
        .onProjectDidCommit(perform: onProjectDidCommit)
        .onChange(of: category, onCategoryDidChange)
        .onAppear(perform: onAppear)
    }
}

// MARK: - Action

extension CommitForm {
    func onProjectDidCommit(_ eventInfo: ProjectEventInfo) {
        self.text = self.category.defaultMessage
    }

    func onCategoryDidChange() {
        self.text = self.category.defaultMessage
    }

    func onAppear() {
        self.text = self.category.defaultMessage
    }
}

// MARK: - Preview

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideTabPicker()
            .hideProjectActions()
    }
    .frame(width: 600)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
