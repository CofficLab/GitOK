import Foundation

/// 根布局左侧 sidebar 的宽度约束。
@MainActor
public struct SidebarWidth: Equatable, Sendable {
    public let minWidth: CGFloat
    public let idealWidth: CGFloat
    public let maxWidth: CGFloat

    public static let standard = Self(minWidth: 180, idealWidth: 220, maxWidth: 400)

    public init(minWidth: CGFloat, idealWidth: CGFloat, maxWidth: CGFloat) {
        let safeMin = minWidth.isFinite ? max(0, minWidth) : 0
        let safeMax: CGFloat
        if maxWidth.isFinite {
            safeMax = max(safeMin, maxWidth)
        } else {
            safeMax = .infinity
        }
        self.minWidth = safeMin
        self.maxWidth = safeMax
        self.idealWidth = Self.clamp(idealWidth, min: safeMin, max: safeMax)
    }

    public func withIdealWidth(_ width: CGFloat) -> Self {
        Self(minWidth: minWidth, idealWidth: width, maxWidth: maxWidth)
    }

    public func clamped(_ width: CGFloat) -> CGFloat {
        Self.clamp(width, min: minWidth, max: maxWidth)
    }

    private static func clamp(_ value: CGFloat, min minimum: CGFloat, max maximum: CGFloat) -> CGFloat {
        let safeValue = value.isFinite ? value : minimum
        return Swift.min(Swift.max(safeValue, minimum), maximum)
    }
}

/// sidebar 宽度偏好的持久化接口。
@MainActor
public protocol SidebarWidthStoring: AnyObject {
    func loadWidth() -> CGFloat?
    func saveWidth(_ width: CGFloat)
}

/// 使用 UserDefaults 保存全局 sidebar 宽度。
@MainActor
public final class UserDefaultsSidebarWidthStore: SidebarWidthStoring {
    private let defaults: UserDefaults
    private let key: String

    public init(
        defaults: UserDefaults = .standard,
        key: String = "com.coffic.gitok.sidebar-width"
    ) {
        self.defaults = defaults
        self.key = key
    }

    public func loadWidth() -> CGFloat? {
        let value = defaults.double(forKey: key)
        return value.isFinite && value > 0 ? CGFloat(value) : nil
    }

    public func saveWidth(_ width: CGFloat) {
        guard width.isFinite, width > 0 else { return }
        defaults.set(Double(width), forKey: key)
    }
}
