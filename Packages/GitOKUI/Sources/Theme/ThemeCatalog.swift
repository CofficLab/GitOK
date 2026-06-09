import Foundation

/// 主题目录不可变快照（便于测试与 UI 绑定）。
public struct ThemeCatalog: Equatable {
    public let themes: [GitOKUIThemeContribution]
    public let selectedId: String

    public init(themes: [GitOKUIThemeContribution], selectedId: String) {
        self.themes = themes
        self.selectedId = selectedId
    }

    public var selected: GitOKUIThemeContribution? {
        themes.first { $0.id == selectedId }
    }

    public var defaultThemeId: String? {
        themes.first?.id
    }

    public static func == (lhs: ThemeCatalog, rhs: ThemeCatalog) -> Bool {
        lhs.selectedId == rhs.selectedId && lhs.themes.map(\.id) == rhs.themes.map(\.id)
    }
}
