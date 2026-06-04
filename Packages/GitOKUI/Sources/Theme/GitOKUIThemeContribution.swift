import SwiftUI

/// 登记到 ``GitOKUIThemeRegistry`` 的完整主题贡献。
public struct GitOKUIThemeContribution: Identifiable {
    public let sortKey: ThemeSortKey
    public let id: String
    public let displayName: String
    public let compactName: String
    public let description: String
    public let iconName: String
    public let iconColor: Color
    public let chromeTheme: any GitOKAppChromeTheme
    public let editorThemeId: String
    public let uiTheme: (any GitOKUITheme)?
    public let attachments: ThemeAttachments

    public var appearanceKind: ThemeAppearanceKind {
        chromeTheme.appearanceKind
    }

    public init(
        sortKey: ThemeSortKey,
        chromeTheme: any GitOKAppChromeTheme,
        editorThemeId: String,
        uiTheme: (any GitOKUITheme)? = nil,
        attachments: ThemeAttachments = ThemeAttachments(),
        editorThemeContributor: AnyObject? = nil,
        fileIconThemeContributor: AnyObject? = nil
    ) {
        self.sortKey = sortKey
        self.id = chromeTheme.identifier
        self.displayName = chromeTheme.displayName
        self.compactName = chromeTheme.compactName
        self.description = chromeTheme.description
        self.iconName = chromeTheme.iconName
        self.iconColor = chromeTheme.iconColor
        self.chromeTheme = chromeTheme
        self.editorThemeId = editorThemeId
        self.uiTheme = uiTheme
        self.attachments = ThemeAttachments(
            editorThemeContributor: editorThemeContributor,
            fileIconThemeContributor: fileIconThemeContributor
        )
    }
}
