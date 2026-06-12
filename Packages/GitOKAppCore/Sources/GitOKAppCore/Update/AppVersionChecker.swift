import Foundation
import OSLog
import SwiftUI

/// 应用版本检查器
/// 用于检测应用是否为新版本首次启动，并触发更新提示
public final class AppVersionChecker: ObservableObject {
    public static let shared = AppVersionChecker()

    private let userDefaultsKey = "com.gitok.lastInstalledBuildVersion"
    private let userDefaults = UserDefaults.standard

    /// 是否为新版本首次启动
    @Published public var isFirstLaunchOfNewVersion = false

    /// 当前 build 版本
    public var currentBuildVersion: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
    }

    /// 上次保存的 build 版本
    public var lastInstalledBuildVersion: String {
        get { userDefaults.string(forKey: userDefaultsKey) ?? "0" }
        set { userDefaults.set(newValue, forKey: userDefaultsKey) }
    }

    private init() {}

    /// 检查是否为新版本首次启动
    /// 应在应用启动时调用
    @MainActor
    public func checkForNewVersion() {
        let currentBuild = currentBuildVersion
        let lastBuild = lastInstalledBuildVersion

        if currentBuild != lastBuild {
            // 新版本首次启动
            isFirstLaunchOfNewVersion = true
            os_log(
                .info,
                "[AppVersionChecker] New version detected: last=%@, current=%@",
                lastBuild,
                currentBuild
            )

            // 立即更新记录，防止重复触发
            lastInstalledBuildVersion = currentBuild
        } else {
            isFirstLaunchOfNewVersion = false
        }
    }
}

/// 新版本更新提示窗口
public struct NewVersionReleaseNotesView: View {
    @ObservedObject private var versionChecker = AppVersionChecker.shared
    @Environment(\.dismiss) private var dismiss

    private let appInfo = AppInfo()

    public init() {}

    public var body: some View {
        VStack(spacing: 16) {
            // 标题
            VStack(spacing: 8) {
                Image(systemName: "party.popper")
                    .font(.system(size: 40))
                    .foregroundColor(.accentColor)

                Text("欢迎使用新版本")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("GitOK \(appInfo.version) (\(appInfo.build))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 24)

            // 更新说明内容
            VStack(alignment: .leading, spacing: 12) {
                Text("查看最新版本变化：")
                    .font(.headline)

                Button(action: {
                    if let url = URL(string: "https://github.com/CofficLab/GitOK/releases/latest") {
                        NSWorkspace.shared.open(url)
                    }
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "doc.text")
                        Text("查看 Release Notes")
                        Image(systemName: "arrow.right")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)

            // 关闭按钮
            Button("开始使用") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom, 24)
        }
        .frame(width: 360)
        .padding()
    }
}
