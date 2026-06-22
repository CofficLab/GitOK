import GitOKAppCore
import Foundation
import GitOKSupportKit
import OSLog
import SwiftUI
import GitOKUI

/// 应用外观设置视图
public struct AppAppearanceSettingView: View, SuperLog {
    /// emoji 标识符
    nonisolated public static let emoji = "🎨"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    @EnvironmentObject private var themeProvider: AppThemeVM

    /// 当前主题
    @State private var selectedThemeId: String = ""

    /// 主题外观分类筛选
    @State private var themeAppearanceFilter: ThemeAppearanceFilter = .all

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 主题选择
                themeSelectionSection
            }
            .padding()
        }
        .navigationTitle(Text("外观"))
        .onAppear(perform: loadData)
    }

    // MARK: - View Components

    private var themeSelectionSection: some View {
        GitOKUI.AppSettingsSection(title: AppearanceSettingsPluginLocalization.string("Theme")) {
            Picker("", selection: $themeAppearanceFilter) {
                ForEach(ThemeAppearanceFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            if filteredThemes.isEmpty {
                GitOKUI.AppSettingsRow(verticalPadding: 10) {
                    HStack(spacing: 12) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(.secondary)
                            .frame(width: 28)

                        Text(AppearanceSettingsPluginLocalization.string("No themes in this category"))
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)

                        Spacer()
                    }
                }
            }

            ForEach(filteredThemes) { theme in
                themeRow(theme)
            }
        }
    }

    private var filteredThemes: [GitOKUIThemeContribution] {
        themeProvider.themes.filter { themeAppearanceFilter.matches($0.appearanceKind) }
    }

    private func themeRow(_ theme: GitOKUIThemeContribution) -> some View {
        GitOKUI.AppSettingsRow(isSelected: selectedThemeId == theme.id, verticalPadding: 10) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(theme.iconColor.opacity(0.18))
                        .frame(width: 32, height: 32)

                    Image(systemName: theme.iconName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.iconColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.displayName)
                        .font(.system(size: 13, weight: .medium))

                    Text(theme.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                HStack(spacing: 5) {
                    Circle()
                        .fill(theme.chromeTheme.accentColors().primary)
                    Circle()
                        .fill(theme.chromeTheme.accentColors().secondary)
                    Circle()
                        .fill(theme.chromeTheme.accentColors().tertiary)
                }
                .frame(width: 48, height: 14)

                if selectedThemeId == theme.id {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 14, weight: .semibold))
                }
            }
        }
        .onTapGesture {
            selectedThemeId = theme.id
            themeProvider.selectTheme(theme.id)
        }
    }

    // MARK: - Actions

    private func loadData() {
        selectedThemeId = themeProvider.currentThemeId

        if Self.verbose {
            os_log("\(Self.t)📋 Loaded current theme: \(selectedThemeId)")
        }
    }
}

enum ThemeAppearanceFilter: String, CaseIterable, Identifiable {
    case all
    case dark
    case light
    case system

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return AppearanceSettingsPluginLocalization.string("All")
        case .dark:
            return AppearanceSettingsPluginLocalization.string("Black")
        case .light:
            return AppearanceSettingsPluginLocalization.string("Light")
        case .system:
            return AppearanceSettingsPluginLocalization.string("System")
        }
    }

    func matches(_ kind: ThemeAppearanceKind) -> Bool {
        switch self {
        case .all:
            return true
        case .dark:
            return kind == .dark
        case .light:
            return kind == .light
        case .system:
            return kind == .system
        }
    }
}
