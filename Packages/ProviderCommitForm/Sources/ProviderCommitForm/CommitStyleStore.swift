import Foundation

/// Commit 风格的全局默认存储（UserDefaults，key 对齐旧版全局风格）。
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
