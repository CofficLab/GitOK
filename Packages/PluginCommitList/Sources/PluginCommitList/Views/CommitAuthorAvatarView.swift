import AppKit
import KitGit
import LumiUI
import SwiftUI

/// 提交作者头像：远程头像加载失败时回退到稳定的首字母头像。
struct CommitAuthorAvatarView: View {
    let author: String
    let email: String
    let size: CGFloat
    let service: CommitAvatarService

    @State private var image: NSImage?

    init(author: String, email: String, size: CGFloat = 18, service: CommitAvatarService) {
        self.author = author
        self.email = email
        self.size = size
        self.service = service
    }

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                fallbackAvatar
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .task(id: "\(author)\u{1f}\(email)") {
            let data = await service.avatarImageData(author: author, email: email)
            image = data.flatMap(NSImage.init(data:))
        }
    }

    private var fallbackAvatar: some View {
        let trimmed = author.trimmingCharacters(in: .whitespacesAndNewlines)
        let initial = trimmed.first.map(String.init) ?? "?"
        let hue = Double(abs(author.hashValue % 360)) / 360.0
        let color = Color(hue: hue, saturation: 0.5, brightness: 0.72)
        return ZStack {
            Circle()
                .fill(color.opacity(0.15))
            Text(initial.uppercased())
                .font(.system(size: max(9, size * 0.5), weight: .medium))
                .foregroundStyle(color)
        }
    }
}