import Foundation

/// 回复详细程度。
public enum ResponseVerbosity: CaseIterable, Codable, Identifiable, RawRepresentable, Sendable {
    case brief
    case standard
    case detailed

    /// 未显式指定时使用的默认级别（单一事实来源）。
    /// 所有回退到默认值的位置都应引用此处，避免各处不一致。
    public static let defaultVerbosity: ResponseVerbosity = .standard

    public var id: String { rawValue }

    public var rawValue: String {
        switch self {
        case .brief: "v1"
        case .standard: "v2"
        case .detailed: "v3"
        }
    }

    public init?(rawValue: String) {
        switch rawValue.lowercased() {
        case "v1", "brief": self = .brief
        case "v2", "standard", "normal": self = .standard
        case "v3", "detailed": self = .detailed
        default: return nil
        }
    }

    public var levelCode: String { rawValue.uppercased() }

    public var displayName: String {
        switch self {
        case .brief: LumiPluginLocalization.string("Brief", bundle: .module)
        case .standard: LumiPluginLocalization.string("Standard", bundle: .module)
        case .detailed: LumiPluginLocalization.string("Detailed", bundle: .module)
        }
    }

    public var iconName: String {
        switch self {
        case .brief: "text.alignleft"
        case .standard: "text.justify.left"
        case .detailed: "doc.richtext"
        }
    }

    public var description: String {
        switch self {
        case .brief: LumiPluginLocalization.string("Return only core conclusions", bundle: .module)
        case .standard: LumiPluginLocalization.string("Include necessary explanations and steps", bundle: .module)
        case .detailed: LumiPluginLocalization.string("Include full reasoning and context", bundle: .module)
        }
    }
}
