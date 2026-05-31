import Foundation

enum GitOperationError: LocalizedError {
    case pushNeedsFetch(message: String)
    case syncNeedsUserDecision(ahead: Int, behind: Int)

    var errorDescription: String? {
        switch self {
        case let .pushNeedsFetch(message):
            return message
        case let .syncNeedsUserDecision(ahead, behind):
            return "本地有 \(ahead) 个未推送提交，远程有 \(behind) 个本地没有的提交。"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .pushNeedsFetch:
            return "请先获取远程更新，然后选择 Pull 或 Rebase 处理本地与远程提交。"
        case .syncNeedsUserDecision:
            return "请先 Pull 或 Rebase 处理分叉后，再执行 Push。"
        }
    }

    static func pushNeedsFetchMessage(from error: Error) -> String? {
        let message = error.localizedDescription
        let lowercased = message.lowercased()
        let markers = [
            "non-fast-forward",
            "fetch first",
            "failed to push some refs",
            "remote contains work that you do not have locally",
            "repository has been updated since you last pulled",
            "tip of your current branch is behind"
        ]

        guard markers.contains(where: { lowercased.contains($0) }) else {
            return nil
        }

        return message.isEmpty ? "远程有新的提交，当前分支无法直接推送。" : message
    }
}
