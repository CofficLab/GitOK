import Foundation

/// 更新状态模型
public enum UpdateState: Equatable, Sendable {
    case idle
    case checking
    case available(updateInfo: UpdateInfo)
    case downloading(progress: Double, speed: String)
    case installing(progress: String)
    case completed
    case error(message: String)

    // 手动实现 Equatable（因为 UpdateInfo 已经实现了 Equatable）
    public static func == (lhs: UpdateState, rhs: UpdateState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.checking, .checking):
            return true
        case (.available(let lhsInfo), .available(let rhsInfo)):
            return lhsInfo == rhsInfo
        case (.downloading(let lhsProgress, let lhsSpeed), .downloading(let rhsProgress, let rhsSpeed)):
            return lhsProgress == rhsProgress && lhsSpeed == rhsSpeed
        case (.installing(let lhsProgress), .installing(let rhsProgress)):
            return lhsProgress == rhsProgress
        case (.completed, .completed):
            return true
        case (.error(let lhsMsg), .error(let rhsMsg)):
            return lhsMsg == rhsMsg
        default:
            return false
        }
    }
}