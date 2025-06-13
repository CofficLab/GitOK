import MagicCore
import SwiftUI

struct UserView: View {
    @EnvironmentObject var data: DataProvider
    
    @State var text: String = ""
    @State var category: CommitCategory = .Chore
    @State var currentUser: String = ""
    @State var currentEmail: String = ""
    @State var showUserConfig = false

    var body: some View {
        HStack {
            MagicButton(icon: .iconSettings) { completion in
                showUserConfig = true
                completion()
            }

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
            } else {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 14))

                    Text("未配置用户信息")
                        .font(.caption)
                        .foregroundColor(.orange)

                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(6)
            }
        }
        .onAppear(perform: onAppear)
    }
}

// MARK: - Action

extension UserView {
    private func loadUserInfo() {
        do {
            let userName = try data.project?.getUserName()
            let userEmail = try data.project?.getUserEmail()

            self.currentUser = userName ?? ""
            self.currentEmail = userEmail ?? ""
        } catch {
            // 如果获取用户信息失败，保持空字符串
            self.currentUser = ""
            self.currentEmail = ""
        }
    }
}

// MARK: - Event 

extension UserView {
    private func onAppear() {
        loadUserInfo()
    }
}

// MARK: - Preview

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()

        .frame(width: 600)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
