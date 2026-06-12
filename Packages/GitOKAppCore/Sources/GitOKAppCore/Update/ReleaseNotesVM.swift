import Foundation
import SwiftUI
import OSLog

/// 发布说明 ViewModel
/// 用于获取和显示最新版本的更新说明
@MainActor
public final class ReleaseNotesVM: ObservableObject {
    nonisolated public static let emoji = "📝"

    @Published public var releaseNotes: String = ""
    @Published public var isLoading: Bool = false
    @Published public var latestVersion: String = ""
    @Published public var hasError: Bool = false

    private let session = URLSession.shared
    private let appInfo = AppInfo()

    public init() {}

    /// 从 GitHub API 获取最新 Release 内容
    public func fetchLatestReleaseNotes() async {
        isLoading = true
        hasError = false

        guard let url = URL(string: "https://api.github.com/repos/CofficLab/GitOK/releases/latest") else {
            hasError = true
            isLoading = false
            return
        }

        do {
            var request = URLRequest(url: url)
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                hasError = true
                isLoading = false
                return
            }

            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                latestVersion = json["tag_name"] as? String ?? ""
                releaseNotes = json["body"] as? String ?? ""
            }
        } catch {
            os_log(.error, "[ReleaseNotesVM] Failed to fetch release notes: %@", error.localizedDescription)
            hasError = true
        }

        isLoading = false
    }
}

/// 发布说明预览组件
/// 在设置页面中直接显示最新版本的更新说明
public struct ReleaseNotesPreviewView: View {
    @StateObject private var vm = ReleaseNotesVM()

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if vm.isLoading {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("加载更新说明...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if vm.hasError {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text("加载失败，请稍后重试")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if !vm.releaseNotes.isEmpty {
                // 显示版本号
                if !vm.latestVersion.isEmpty {
                    Text("最新版本: \(vm.latestVersion)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 4)
                }

                // 显示 Markdown 格式的更新说明
                ScrollView {
                    Text(vm.releaseNotes)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                }
                .frame(maxHeight: 200)
            }
        }
        .padding(12)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
        .task {
            await vm.fetchLatestReleaseNotes()
        }
    }
}
