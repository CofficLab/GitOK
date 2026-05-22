import GitOKUI
import SwiftUI

private struct GitOKScenarioTheme: GitOKAppChromeTheme {
    let identifier: String
    let displayName: String
    let compactName: String
    let description: String
    let iconName: String
    let iconColor: Color
    let isDarkTheme: Bool
    let followsSystemAppearance: Bool
    let deep: Color
    let medium: Color
    let light: Color
    let primary: Color
    let secondary: Color
    let tertiary: Color
    let text: Color
    let secondaryText: Color
    let tertiaryText: Color

    func accentColors() -> (primary: Color, secondary: Color, tertiary: Color) {
        (primary, secondary, tertiary)
    }

    func atmosphereColors() -> (deep: Color, medium: Color, light: Color) {
        (deep, medium, light)
    }

    func glowColors() -> (subtle: Color, medium: Color, intense: Color) {
        (
            subtle: primary.opacity(isDarkTheme ? 0.12 : 0.08),
            medium: secondary.opacity(isDarkTheme ? 0.16 : 0.10),
            intense: tertiary.opacity(isDarkTheme ? 0.18 : 0.12)
        )
    }

    func workspaceBackgroundColor() -> Color {
        medium
    }

    func sidebarBackgroundColor() -> Color {
        deep
    }

    func sidebarSelectionColor() -> Color {
        primary.opacity(isDarkTheme ? 0.24 : 0.14)
    }

    func sidebarSelectionTextColor() -> Color {
        isDarkTheme ? .white : Color(hex: "111827")
    }

    func workspaceTextColor() -> Color {
        text
    }

    func workspaceSecondaryTextColor() -> Color {
        secondaryText
    }

    func workspaceTertiaryTextColor() -> Color {
        tertiaryText
    }

    func makeGlobalBackground(proxy: GeometryProxy) -> AnyView {
        AnyView(
            ZStack {
                backgroundGradient()

                VStack(spacing: 0) {
                    Rectangle()
                        .fill(primary.opacity(isDarkTheme ? 0.10 : 0.05))
                        .frame(height: 1)
                    Spacer()
                    Rectangle()
                        .fill(secondary.opacity(isDarkTheme ? 0.08 : 0.04))
                        .frame(height: 1)
                }
                .padding(.horizontal, 24)

                HStack(spacing: 0) {
                    Rectangle()
                        .fill(primary.opacity(isDarkTheme ? 0.08 : 0.04))
                        .frame(width: 1)
                    Spacer()
                    Rectangle()
                        .fill(tertiary.opacity(isDarkTheme ? 0.06 : 0.035))
                        .frame(width: 1)
                }
                .padding(.vertical, 20)
            }
        )
    }
}

private extension GitOKScenarioTheme {
    static let repository = GitOKScenarioTheme(
        identifier: "repository",
        displayName: "Repository",
        compactName: "Repo",
        description: "Balanced repository workspace with GitHub-inspired contrast",
        iconName: "folder.badge.gearshape",
        iconColor: Color.adaptive(light: "2563EB", dark: "58A6FF"),
        isDarkTheme: true,
        followsSystemAppearance: false,
        deep: Color(hex: "0D1117"),
        medium: Color(hex: "161B22"),
        light: Color(hex: "21262D"),
        primary: Color(hex: "58A6FF"),
        secondary: Color(hex: "3FB950"),
        tertiary: Color(hex: "BC8CFF"),
        text: Color(hex: "F0F6FC"),
        secondaryText: Color(hex: "C9D1D9"),
        tertiaryText: Color(hex: "8B949E")
    )

    static let worktree = GitOKScenarioTheme(
        identifier: "worktree",
        displayName: "Worktree",
        compactName: "Work",
        description: "Calm light theme for scanning projects, branches, and files",
        iconName: "tree",
        iconColor: Color(hex: "047857"),
        isDarkTheme: false,
        followsSystemAppearance: false,
        deep: Color(hex: "F5F7F4"),
        medium: Color(hex: "FFFFFF"),
        light: Color(hex: "E6ECE6"),
        primary: Color(hex: "047857"),
        secondary: Color(hex: "2563EB"),
        tertiary: Color(hex: "B45309"),
        text: Color(hex: "172019"),
        secondaryText: Color(hex: "4B5B50"),
        tertiaryText: Color(hex: "78857D")
    )

    static let commitGraph = GitOKScenarioTheme(
        identifier: "commit-graph",
        displayName: "Commit Graph",
        compactName: "Graph",
        description: "High-contrast dark theme for history, graph lines, and status review",
        iconName: "point.3.connected.trianglepath.dotted",
        iconColor: Color(hex: "22D3EE"),
        isDarkTheme: true,
        followsSystemAppearance: false,
        deep: Color(hex: "071118"),
        medium: Color(hex: "0E1B24"),
        light: Color(hex: "162A36"),
        primary: Color(hex: "22D3EE"),
        secondary: Color(hex: "A3E635"),
        tertiary: Color(hex: "F59E0B"),
        text: Color(hex: "ECFEFF"),
        secondaryText: Color(hex: "B6D7DF"),
        tertiaryText: Color(hex: "7FA6B1")
    )

    static let terminal = GitOKScenarioTheme(
        identifier: "terminal",
        displayName: "Terminal",
        compactName: "Term",
        description: "Quiet command-line palette for pull, push, fetch, and automation work",
        iconName: "terminal",
        iconColor: Color(hex: "34D399"),
        isDarkTheme: true,
        followsSystemAppearance: false,
        deep: Color(hex: "050807"),
        medium: Color(hex: "0B1110"),
        light: Color(hex: "14201D"),
        primary: Color(hex: "34D399"),
        secondary: Color(hex: "60A5FA"),
        tertiary: Color(hex: "FBBF24"),
        text: Color(hex: "E8FFF7"),
        secondaryText: Color(hex: "A8C7BD"),
        tertiaryText: Color(hex: "6F8C83")
    )

    static let conflict = GitOKScenarioTheme(
        identifier: "conflict",
        displayName: "Conflict",
        compactName: "Conflict",
        description: "Focused review theme for merge conflicts and risky changes",
        iconName: "exclamationmark.triangle",
        iconColor: Color(hex: "F97316"),
        isDarkTheme: true,
        followsSystemAppearance: false,
        deep: Color(hex: "17120F"),
        medium: Color(hex: "221A16"),
        light: Color(hex: "31231C"),
        primary: Color(hex: "F97316"),
        secondary: Color(hex: "EF4444"),
        tertiary: Color(hex: "FACC15"),
        text: Color(hex: "FFF7ED"),
        secondaryText: Color(hex: "FED7AA"),
        tertiaryText: Color(hex: "C69A74")
    )
}

private func themeContribution(_ theme: GitOKScenarioTheme, order: Int) -> GitOKUIThemeContribution {
    GitOKUIThemeContribution(
        sortKey: ThemeSortKey(pluginOrder: order, themeId: theme.identifier),
        chromeTheme: theme,
        editorThemeId: theme.identifier
    )
}

class ThemeRepositoryPlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeRepositoryPlugin()
    static var order: Int { 120 }
    static var displayName: String { "Repository Theme" }
    static var description: String { "Repository-focused dark theme" }
    static var iconName: String { "folder.badge.gearshape" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeRepositoryPlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.repository, order: Self.order)]
    }
}

class ThemeWorktreePlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeWorktreePlugin()
    static var order: Int { 121 }
    static var displayName: String { "Worktree Theme" }
    static var description: String { "Light worktree browsing theme" }
    static var iconName: String { "tree" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeWorktreePlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.worktree, order: Self.order)]
    }
}

class ThemeCommitGraphPlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeCommitGraphPlugin()
    static var order: Int { 122 }
    static var displayName: String { "Commit Graph Theme" }
    static var description: String { "Theme for reviewing commit history" }
    static var iconName: String { "point.3.connected.trianglepath.dotted" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeCommitGraphPlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.commitGraph, order: Self.order)]
    }
}

class ThemeTerminalPlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeTerminalPlugin()
    static var order: Int { 123 }
    static var displayName: String { "Terminal Theme" }
    static var description: String { "Command-line oriented dark theme" }
    static var iconName: String { "terminal" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeTerminalPlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.terminal, order: Self.order)]
    }
}

class ThemeConflictPlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeConflictPlugin()
    static var order: Int { 124 }
    static var displayName: String { "Conflict Theme" }
    static var description: String { "Focused merge conflict review theme" }
    static var iconName: String { "exclamationmark.triangle" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeConflictPlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.conflict, order: Self.order)]
    }
}
