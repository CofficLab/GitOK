import Foundation
import ProviderStorage

/// Commit 风格的全局默认存储（UserDefaults，key 对齐旧版全局风格）。
///
/// 该值是**新项目 / 未记录项目的默认风格**，不再是全局唯一风格：
/// 每个项目的实际风格由 `DefaultCommitFormProvider` 按项目持久化，
/// 只有该项目尚无记录时才回退到这里。
public enum CommitStyleStore {
    private static let key = "GitOK_GlobalCommitStyle"

    /// 当前全局默认风格。
    public static var current: CommitStyle {
        guard let raw = UserDefaults.standard.string(forKey: key),
              let style = CommitStyle(rawValue: raw) else {
            return .emoji
        }
        return style
    }

    /// 设置全局默认风格。
    public static func set(_ style: CommitStyle) {
        UserDefaults.standard.set(style.rawValue, forKey: key)
    }
}

/// 每个项目的 Commit 风格存储。
///
/// 持久化为插件数据目录下的 JSON 文件，键为项目的标准化路径
/// （`standardizedFileURL.path`），与 `DefaultAutoPushProvider` 的按项目
/// 存储保持一致。
///
/// 未注入 `StorageProviding` 时退化为纯内存模式（测试 / 预览场景），
/// 读写仍然可用，只是不落盘。
@MainActor
public final class CommitStylePerProjectStore {
    /// 项目路径 → 风格 rawValue。
    private var styles: [String: String]
    private let fileURL: URL?

    /// - Parameter directory: 数据目录；传 `nil` 时仅使用内存。
    public init(directory: URL?) {
        guard let directory else {
            self.fileURL = nil
            self.styles = [:]
            return
        }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("commit-style-by-project.json")
        self.fileURL = url
        if let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            self.styles = decoded
        } else {
            self.styles = [:]
        }
    }

    /// 读取指定项目的风格；无记录时返回 `nil`（由调用方决定回退策略）。
    public func style(for projectURL: URL) -> CommitStyle? {
        guard let raw = styles[key(for: projectURL)] else { return nil }
        return CommitStyle(rawValue: raw)
    }

    /// 写入指定项目的风格并持久化。
    public func setStyle(_ style: CommitStyle, for projectURL: URL) {
        styles[key(for: projectURL)] = style.rawValue
        save()
    }

    /// 项目键：标准化路径，避免同一仓库的不同写法产生重复记录。
    private func key(for projectURL: URL) -> String {
        projectURL.standardizedFileURL.path
    }

    private func save() {
        guard let fileURL, let data = try? JSONEncoder().encode(styles) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
