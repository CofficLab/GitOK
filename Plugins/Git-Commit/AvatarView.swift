import SwiftUI

/// 头像视图组件
struct AvatarView: View {
    let user: AvatarUser
    let size: CGFloat

    @StateObject private var avatarService = AvatarService.shared
    @State private var avatarURL: URL?
    @State private var isLoading = true

    init(user: AvatarUser, size: CGFloat = 32) {
        self.user = user
        self.size = size
    }

    var body: some View {
        Group {
            if let url = avatarURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure(_):
                        defaultAvatar
                    case .empty:
                        ProgressView()
                            .controlSize(.small)
                    @unknown default:
                        defaultAvatar
                    }
                }
            } else {
                defaultAvatar
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .onAppear {
            loadAvatar()
        }
    }

    /// 默认头像（首字母或默认图标）
    private var defaultAvatar: some View {
        ZStack {
            Circle()
                .fill(Color.secondary.opacity(0.2))

            if let firstLetter = user.name.first {
                Text(String(firstLetter))
                    .font(.system(size: size * 0.5, weight: .medium))
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: "person.circle")
                    .font(.system(size: size * 0.8))
                    .foregroundColor(.secondary)
            }
        }
    }

    /// 加载头像
    private func loadAvatar() {
        Task {
            isLoading = true
            let url = await avatarService.getAvatarURL(name: user.name, email: user.email)
            await MainActor.run {
                self.avatarURL = url ?? avatarService.getGravatarURL(email: user.email, size: Int(size))
                self.isLoading = false
            }
        }
    }
}

#Preview("Avatar View") {
    VStack(spacing: 16) {
        HStack(spacing: 12) {
            AvatarView(user: AvatarUser(name: "John Doe", email: "john@example.com"), size: 32)
            AvatarView(user: AvatarUser(name: "Jane Smith", email: "jane@example.com"), size: 40)
            AvatarView(user: AvatarUser(name: "Bob Wilson", email: "bob@example.com"), size: 48)
        }

        HStack(spacing: 12) {
            AvatarView(user: AvatarUser(name: "Test User", email: "test@github.com"), size: 32)
            AvatarView(user: AvatarUser(name: "A", email: "a@b.com"), size: 40)
            AvatarView(user: AvatarUser(name: "", email: "anonymous@example.com"), size: 48)
        }
    }
    .padding()
}

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .hideTabPicker()
        .inRootView()
        .frame(width: 800)
        .frame(height: 1000)
}
