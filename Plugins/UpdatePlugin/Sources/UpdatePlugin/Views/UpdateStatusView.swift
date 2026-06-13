import SwiftUI

/// 更新状态视图（状态栏指示器）
public struct UpdateStatusView: View {
    @StateObject private var checker = UpdateChecker()

    public init() {}

    public var body: some View {
        Group {
            if checker.isChecking {
                // 检查中：显示进度图标
                ProgressView()
                    .controlSize(.small)
            } else if let updateInfo = checker.latestVersion, updateInfo.isNewerThanCurrent {
                // 有新版本：显示提示图标
                Button(action: {
                    // TODO: 打开更新弹窗
                }) {
                    Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                        .foregroundColor(.accentColor)
                }
                .help("有新版本 \(updateInfo.version) 可用")
            } else {
                // 无更新：隐藏
                EmptyView()
            }
        }
        .task {
            // 启动时检查更新（延迟3秒）
            try? await Task.sleep(for: .seconds(3))
            await checker.checkForUpdates()
        }
    }
}