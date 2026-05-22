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

    static let branchFlow = GitOKScenarioTheme(
        identifier: "branch-flow",
        displayName: "Branch Flow",
        compactName: "Branch",
        description: "Green-blue branch management theme for switching, creating, and pruning branches",
        iconName: "arrow.triangle.branch",
        iconColor: Color(hex: "2DD4BF"),
        isDarkTheme: true,
        followsSystemAppearance: false,
        deep: Color(hex: "061414"),
        medium: Color(hex: "0B1F1D"),
        light: Color(hex: "14302D"),
        primary: Color(hex: "2DD4BF"),
        secondary: Color(hex: "38BDF8"),
        tertiary: Color(hex: "84CC16"),
        text: Color(hex: "F0FDFA"),
        secondaryText: Color(hex: "B7DCD6"),
        tertiaryText: Color(hex: "789995")
    )

    static let pullRequest = GitOKScenarioTheme(
        identifier: "pull-request",
        displayName: "Pull Request",
        compactName: "PR",
        description: "Review-focused theme for comparing incoming changes and branch readiness",
        iconName: "arrow.triangle.pull",
        iconColor: Color(hex: "A78BFA"),
        isDarkTheme: true,
        followsSystemAppearance: false,
        deep: Color(hex: "120F1C"),
        medium: Color(hex: "1B1728"),
        light: Color(hex: "29223A"),
        primary: Color(hex: "A78BFA"),
        secondary: Color(hex: "22D3EE"),
        tertiary: Color(hex: "F472B6"),
        text: Color(hex: "F7F2FF"),
        secondaryText: Color(hex: "D8CFF0"),
        tertiaryText: Color(hex: "9E91BC")
    )

    static let remote = GitOKScenarioTheme(
        identifier: "remote",
        displayName: "Remote",
        compactName: "Remote",
        description: "Network-oriented theme for remotes, fetch, pull, and push operations",
        iconName: "network",
        iconColor: Color(hex: "38BDF8"),
        isDarkTheme: true,
        followsSystemAppearance: false,
        deep: Color(hex: "07121F"),
        medium: Color(hex: "0D1B2A"),
        light: Color(hex: "16324A"),
        primary: Color(hex: "38BDF8"),
        secondary: Color(hex: "818CF8"),
        tertiary: Color(hex: "2DD4BF"),
        text: Color(hex: "F0F9FF"),
        secondaryText: Color(hex: "B8D7EA"),
        tertiaryText: Color(hex: "7B9DB6")
    )

    static let stash = GitOKScenarioTheme(
        identifier: "stash",
        displayName: "Stash",
        compactName: "Stash",
        description: "Low-noise theme for temporary work, shelves, and context switching",
        iconName: "tray.full",
        iconColor: Color(hex: "FBBF24"),
        isDarkTheme: true,
        followsSystemAppearance: false,
        deep: Color(hex: "15130B"),
        medium: Color(hex: "211D12"),
        light: Color(hex: "332B17"),
        primary: Color(hex: "FBBF24"),
        secondary: Color(hex: "60A5FA"),
        tertiary: Color(hex: "A3E635"),
        text: Color(hex: "FFFBEA"),
        secondaryText: Color(hex: "E8D9A6"),
        tertiaryText: Color(hex: "A99B70")
    )

    static let lfs = GitOKScenarioTheme(
        identifier: "large-files",
        displayName: "Large Files",
        compactName: "LFS",
        description: "Dense theme for Git LFS, binary assets, and repository storage review",
        iconName: "externaldrive",
        iconColor: Color(hex: "06B6D4"),
        isDarkTheme: false,
        followsSystemAppearance: false,
        deep: Color(hex: "EEF8FA"),
        medium: Color(hex: "FAFEFF"),
        light: Color(hex: "D7EDF2"),
        primary: Color(hex: "0891B2"),
        secondary: Color(hex: "0F766E"),
        tertiary: Color(hex: "7C3AED"),
        text: Color(hex: "102A33"),
        secondaryText: Color(hex: "3C5963"),
        tertiaryText: Color(hex: "718892")
    )

    static let release = GitOKScenarioTheme(
        identifier: "release",
        displayName: "Release",
        compactName: "Release",
        description: "Crisp theme for tags, versions, changelog checks, and release preparation",
        iconName: "tag",
        iconColor: Color(hex: "EAB308"),
        isDarkTheme: false,
        followsSystemAppearance: false,
        deep: Color(hex: "F7F5EF"),
        medium: Color(hex: "FFFDF7"),
        light: Color(hex: "EDE6D2"),
        primary: Color(hex: "B45309"),
        secondary: Color(hex: "2563EB"),
        tertiary: Color(hex: "16A34A"),
        text: Color(hex: "241D12"),
        secondaryText: Color(hex: "60533D"),
        tertiaryText: Color(hex: "94866E")
    )

    static let automation = GitOKScenarioTheme(
        identifier: "automation",
        displayName: "Automation",
        compactName: "Auto",
        description: "Signal-forward theme for watchers, auto-pull, auto-push, and background tasks",
        iconName: "gearshape.2",
        iconColor: Color(hex: "22C55E"),
        isDarkTheme: true,
        followsSystemAppearance: false,
        deep: Color(hex: "08130B"),
        medium: Color(hex: "0E1D12"),
        light: Color(hex: "182B1D"),
        primary: Color(hex: "22C55E"),
        secondary: Color(hex: "38BDF8"),
        tertiary: Color(hex: "FACC15"),
        text: Color(hex: "F0FDF4"),
        secondaryText: Color(hex: "B7DCC0"),
        tertiaryText: Color(hex: "7F9D87")
    )

    static let archive = GitOKScenarioTheme(
        identifier: "archive",
        displayName: "Archive",
        compactName: "Archive",
        description: "Quiet light theme for old repositories, cleanup passes, and reference browsing",
        iconName: "archivebox",
        iconColor: Color(hex: "64748B"),
        isDarkTheme: false,
        followsSystemAppearance: false,
        deep: Color(hex: "F1F5F9"),
        medium: Color(hex: "FFFFFF"),
        light: Color(hex: "E2E8F0"),
        primary: Color(hex: "475569"),
        secondary: Color(hex: "0F766E"),
        tertiary: Color(hex: "7C2D12"),
        text: Color(hex: "172033"),
        secondaryText: Color(hex: "4B5565"),
        tertiaryText: Color(hex: "7B8494")
    )

    static let focus = GitOKScenarioTheme(
        identifier: "focus",
        displayName: "Focus",
        compactName: "Focus",
        description: "Minimal light theme for long status review sessions and careful commits",
        iconName: "scope",
        iconColor: Color(hex: "2563EB"),
        isDarkTheme: false,
        followsSystemAppearance: false,
        deep: Color(hex: "F8FAFC"),
        medium: Color(hex: "FFFFFF"),
        light: Color(hex: "E5EAF2"),
        primary: Color(hex: "2563EB"),
        secondary: Color(hex: "059669"),
        tertiary: Color(hex: "9333EA"),
        text: Color(hex: "111827"),
        secondaryText: Color(hex: "4B5563"),
        tertiaryText: Color(hex: "7C8594")
    )

    static let graphite = GitOKScenarioTheme(
        identifier: "graphite",
        displayName: "Graphite",
        compactName: "Graphite",
        description: "Neutral dark theme for dense repository dashboards and repeated operations",
        iconName: "square.grid.3x3",
        iconColor: Color(hex: "94A3B8"),
        isDarkTheme: true,
        followsSystemAppearance: false,
        deep: Color(hex: "0A0C0F"),
        medium: Color(hex: "111418"),
        light: Color(hex: "1E242B"),
        primary: Color(hex: "94A3B8"),
        secondary: Color(hex: "22C55E"),
        tertiary: Color(hex: "60A5FA"),
        text: Color(hex: "F1F5F9"),
        secondaryText: Color(hex: "CBD5E1"),
        tertiaryText: Color(hex: "8794A5")
    )

    static let dracula = GitOKScenarioTheme(
        identifier: "dracula",
        displayName: "Dracula",
        compactName: "Dracula",
        description: "Vivid dark theme for late-night Git work and high-visibility status colors",
        iconName: "moon.stars",
        iconColor: Color(hex: "BD93F9"),
        isDarkTheme: true,
        followsSystemAppearance: false,
        deep: Color(hex: "191A21"),
        medium: Color(hex: "282A36"),
        light: Color(hex: "343746"),
        primary: Color(hex: "BD93F9"),
        secondary: Color(hex: "50FA7B"),
        tertiary: Color(hex: "FFB86C"),
        text: Color(hex: "F8F8F2"),
        secondaryText: Color(hex: "D6D4E4"),
        tertiaryText: Color(hex: "8E90A6")
    )

    static let oneDark = GitOKScenarioTheme(
        identifier: "one-dark",
        displayName: "One Dark",
        compactName: "One",
        description: "Editor-style dark theme for code-heavy diffs and commit message work",
        iconName: "chevron.left.forwardslash.chevron.right",
        iconColor: Color(hex: "61AFEF"),
        isDarkTheme: true,
        followsSystemAppearance: false,
        deep: Color(hex: "1E222A"),
        medium: Color(hex: "282C34"),
        light: Color(hex: "353B45"),
        primary: Color(hex: "61AFEF"),
        secondary: Color(hex: "98C379"),
        tertiary: Color(hex: "E5C07B"),
        text: Color(hex: "ABB2BF"),
        secondaryText: Color(hex: "C8CCD4"),
        tertiaryText: Color(hex: "7F8794")
    )

    static let xcodeLight = GitOKScenarioTheme(
        identifier: "xcode-light",
        displayName: "Xcode Light",
        compactName: "Xcode",
        description: "Bright macOS-native theme for app repository work and Xcode handoffs",
        iconName: "hammer",
        iconColor: Color(hex: "0A84FF"),
        isDarkTheme: false,
        followsSystemAppearance: false,
        deep: Color(hex: "F2F6FC"),
        medium: Color(hex: "FFFFFF"),
        light: Color(hex: "DDE7F5"),
        primary: Color(hex: "0A84FF"),
        secondary: Color(hex: "30D158"),
        tertiary: Color(hex: "FF9F0A"),
        text: Color(hex: "1D1D1F"),
        secondaryText: Color(hex: "515A66"),
        tertiaryText: Color(hex: "8B95A3")
    )

    static let githubLight = GitOKScenarioTheme(
        identifier: "github-light",
        displayName: "GitHub Light",
        compactName: "GitHub",
        description: "Clean GitHub-like light theme for remote review and issue-linked work",
        iconName: "globe",
        iconColor: Color(hex: "0969DA"),
        isDarkTheme: false,
        followsSystemAppearance: false,
        deep: Color(hex: "F6F8FA"),
        medium: Color(hex: "FFFFFF"),
        light: Color(hex: "D8DEE4"),
        primary: Color(hex: "0969DA"),
        secondary: Color(hex: "1A7F37"),
        tertiary: Color(hex: "9A6700"),
        text: Color(hex: "24292F"),
        secondaryText: Color(hex: "57606A"),
        tertiaryText: Color(hex: "8C959F")
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

class ThemeBranchFlowPlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeBranchFlowPlugin()
    static var order: Int { 125 }
    static var displayName: String { "Branch Flow Theme" }
    static var description: String { "Branch management theme" }
    static var iconName: String { "arrow.triangle.branch" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeBranchFlowPlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.branchFlow, order: Self.order)]
    }
}

class ThemePullRequestPlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemePullRequestPlugin()
    static var order: Int { 126 }
    static var displayName: String { "Pull Request Theme" }
    static var description: String { "Incoming changes review theme" }
    static var iconName: String { "arrow.triangle.pull" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemePullRequestPlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.pullRequest, order: Self.order)]
    }
}

class ThemeRemotePlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeRemotePlugin()
    static var order: Int { 127 }
    static var displayName: String { "Remote Theme" }
    static var description: String { "Remote repository operations theme" }
    static var iconName: String { "network" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeRemotePlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.remote, order: Self.order)]
    }
}

class ThemeStashPlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeStashPlugin()
    static var order: Int { 128 }
    static var displayName: String { "Stash Theme" }
    static var description: String { "Temporary work theme" }
    static var iconName: String { "tray.full" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeStashPlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.stash, order: Self.order)]
    }
}

class ThemeLargeFilesPlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeLargeFilesPlugin()
    static var order: Int { 129 }
    static var displayName: String { "Large Files Theme" }
    static var description: String { "Git LFS and binary asset theme" }
    static var iconName: String { "externaldrive" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeLargeFilesPlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.lfs, order: Self.order)]
    }
}

class ThemeReleasePlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeReleasePlugin()
    static var order: Int { 130 }
    static var displayName: String { "Release Theme" }
    static var description: String { "Tags and release preparation theme" }
    static var iconName: String { "tag" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeReleasePlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.release, order: Self.order)]
    }
}

class ThemeAutomationPlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeAutomationPlugin()
    static var order: Int { 131 }
    static var displayName: String { "Automation Theme" }
    static var description: String { "Background Git task theme" }
    static var iconName: String { "gearshape.2" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeAutomationPlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.automation, order: Self.order)]
    }
}

class ThemeArchivePlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeArchivePlugin()
    static var order: Int { 132 }
    static var displayName: String { "Archive Theme" }
    static var description: String { "Repository cleanup and archive theme" }
    static var iconName: String { "archivebox" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeArchivePlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.archive, order: Self.order)]
    }
}

class ThemeFocusPlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeFocusPlugin()
    static var order: Int { 133 }
    static var displayName: String { "Focus Theme" }
    static var description: String { "Minimal status review theme" }
    static var iconName: String { "scope" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeFocusPlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.focus, order: Self.order)]
    }
}

class ThemeGraphitePlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeGraphitePlugin()
    static var order: Int { 134 }
    static var displayName: String { "Graphite Theme" }
    static var description: String { "Neutral dense dashboard theme" }
    static var iconName: String { "square.grid.3x3" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeGraphitePlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.graphite, order: Self.order)]
    }
}

class ThemeDraculaPlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeDraculaPlugin()
    static var order: Int { 135 }
    static var displayName: String { "Dracula Theme" }
    static var description: String { "Vivid dark Git theme" }
    static var iconName: String { "moon.stars" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeDraculaPlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.dracula, order: Self.order)]
    }
}

class ThemeOneDarkPlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeOneDarkPlugin()
    static var order: Int { 136 }
    static var displayName: String { "One Dark Theme" }
    static var description: String { "Code-heavy diff review theme" }
    static var iconName: String { "chevron.left.forwardslash.chevron.right" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeOneDarkPlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.oneDark, order: Self.order)]
    }
}

class ThemeXcodeLightPlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeXcodeLightPlugin()
    static var order: Int { 137 }
    static var displayName: String { "Xcode Light Theme" }
    static var description: String { "macOS-native light theme" }
    static var iconName: String { "hammer" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeXcodeLightPlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.xcodeLight, order: Self.order)]
    }
}

class ThemeGitHubLightPlugin: NSObject, SuperPlugin {
    @objc static let shared = ThemeGitHubLightPlugin()
    static var order: Int { 138 }
    static var displayName: String { "GitHub Light Theme" }
    static var description: String { "GitHub-like light review theme" }
    static var iconName: String { "globe" }
    static var allowUserToggle: Bool { false }
    nonisolated var instanceLabel: String { "ThemeGitHubLightPlugin" }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        [themeContribution(.githubLight, order: Self.order)]
    }
}
