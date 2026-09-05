import Foundation

/// 读取 git 用户配置（`user.name` / `user.email`）。
///
/// 未配置时返回 nil（不抛错），供提交表单与用户设置页使用。
public enum GitConfigReader {
    /// 读取仓库或全局的用户配置。
    ///
    /// 优先读取仓库级配置；仓库未配置时回退全局配置。
    public static func user(in repository: URL) -> (name: String?, email: String?) {
        (
            name: value("user.name", in: repository),
            email: value("user.email", in: repository)
        )
    }

    /// 读取指定配置键的值（仓库级，未配置回退全局）；失败返回 nil。
    public static func value(_ key: String, in repository: URL) -> String? {
        let trimmed = (try? GitProcessRunner.run(["config", key], in: repository))?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmed, !trimmed.isEmpty else { return nil }
        return trimmed
    }

    /// 仓库级配置缺失时回退读取全局配置。
    public static func globalValue(_ key: String) -> String? {
        let trimmed = (try? GitProcessRunner.run(
            ["config", "--global", key],
            in: FileManager.default.homeDirectoryForCurrentUser
        ))?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmed, !trimmed.isEmpty else { return nil }
        return trimmed
    }

    /// 写入仓库级配置（用于用户设置保存）。
    public static func setValue(_ key: String, _ value: String, in repository: URL) throws {
        _ = try GitProcessRunner.run(["config", key, value], in: repository)
    }

    /// 写入全局配置（用于用户设置保存）。
    public static func setGlobalValue(_ key: String, _ value: String) throws {
        _ = try GitProcessRunner.run(
            ["config", "--global", key, value],
            in: FileManager.default.homeDirectoryForCurrentUser
        )
    }
}
