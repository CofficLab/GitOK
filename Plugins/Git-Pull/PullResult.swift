import Foundation

/// 自动拉取结果数据模型
struct PullResult {
    /// 是否成功
    let success: Bool
    /// 拉取时间戳
    let timestamp: Date
    /// 拉取到的提交数量（成功时有效）
    let pulledCommitCount: Int?
    /// 错误信息（失败时有效）
    let error: Error?

    /// 本地化消息
    var localizedMessage: String {
        if success {
            if let count = pulledCommitCount, count > 0 {
                return "已自动拉取 \(count) 个新提交"
            } else {
                return "已是最新"
            }
        } else {
            return "自动拉取失败"
        }
    }

    /// 创建成功结果
    static func success(commitCount: Int) -> PullResult {
        return PullResult(
            success: true,
            timestamp: Date(),
            pulledCommitCount: commitCount,
            error: nil
        )
    }

    /// 创建失败结果
    static func failure(_ error: Error) -> PullResult {
        return PullResult(
            success: false,
            timestamp: Date(),
            pulledCommitCount: nil,
            error: error
        )
    }
}
