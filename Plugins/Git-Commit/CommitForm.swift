import SwiftUI
import OSLog
import MagicCore

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

        return "\(category.text) \(c)"
    }

    var body: some View {
        if let project = g.project {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    // 当前分支信息显示区域
                    if let currentBranch = g.branch {
                        HStack {
                            Image(systemName: "arrow.branch")
                                .foregroundColor(.secondary)
                                .font(.system(size: 14))

                            Text(currentBranch.name)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        .padding(.trailing, 12)
                    }

                    Picker("", selection: $category, content: {
                        ForEach(CommitCategory.allCases, id: \.self, content: {
                            Text($0.label).tag($0 as CommitCategory?)
                        })
                    })
                    .frame(width: 135)
                    .pickerStyle(.automatic)

                    Spacer()
                    TextField("commit", text: $text)
                        .textFieldStyle(.roundedBorder)
                        .padding(.vertical)
                }

                HStack {
                    UserView()

                    BtnCommitAndPush(commitMessage: commitMessage)
                }
                .frame(height: 40)
            }
            .onNotification(.projectDidCommit, perform: { _ in
                self.text = self.category.defaultMessage
            })
            .onChange(of: category, {
                self.text = category.defaultMessage
            })
            .onAppear {
                self.text = self.category.defaultMessage
            }
        }
    }
}

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
