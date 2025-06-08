import SwiftUI

struct CommitForm: View {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var g: DataProvider

    @State var text: String = ""
    @State var category: CommitCategory = .Chore
    @State var currentUser: String = ""
    @State var currentEmail: String = ""

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
                    if let currentBranch = g.currentBranch {
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
                    
                    CommitCategoryPicker(selection: $category, project: project)
                        .onChange(of: category, {
                            self.text = category.defaultMessage
                        })

                    Spacer()
                    TextField("commit", text: $text)
                        .textFieldStyle(.roundedBorder)
                        .onAppear {
                            self.text = self.category.defaultMessage
                            loadUserInfo(for: project.path)
                        }
                        .padding(.vertical)
                }

                HStack {
                    // 用户信息显示区域
                    if !currentUser.isEmpty {
                        HStack {
                            Image(systemName: "person.circle")
                                .foregroundColor(.secondary)
                                .font(.system(size: 14))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(currentUser)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                if !currentEmail.isEmpty {
                                    Text(currentEmail)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(6)
                    }

                    BtnCommitAndPush(repoPath: project.path, commitMessage: commitMessage)
                }
                .frame(height: 40)
            }
            .onReceive(NotificationCenter.default.publisher(for: .gitCommitSuccess)) { _ in
                self.text = self.category.defaultMessage
            }
        }
    }

    private func loadUserInfo(for projectPath: String) {
        do {
            let userName = try GitShell.getUserName(projectPath)
            let userEmail = try GitShell.getUserEmail(projectPath)

            self.currentUser = userName
            self.currentEmail = userEmail
        } catch {
            // 如果获取用户信息失败，保持空字符串
            self.currentUser = ""
            self.currentEmail = ""
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
