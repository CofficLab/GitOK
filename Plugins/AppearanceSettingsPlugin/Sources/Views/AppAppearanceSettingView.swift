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

    @StateObject private var settings = AppAppearanceSettingsStore.shared
    @EnvironmentObject private var themeProvider: AppThemeVM

    /// 主题模式
    @State private var themeMode: AppAppearanceSettingsStore.ThemeMode = .system

    /// 当前主题
    @State private var selectedThemeId: String = ""

    /// 主题外观分类筛选
    @State private var themeAppearanceFilter: ThemeAppearanceFilter = .all

    /// 强调色
    @State private var accentColor: AppAppearanceSettingsStore.AccentColor = .blue

    /// 字体大小
    @State private var fontSize: AppAppearanceSettingsStore.FontSize = .medium

    /// 布局密度
    @State private var layoutDensity: AppAppearanceSettingsStore.LayoutDensity = .comfortable

    /// 显示重置确认对话框
    @State private var showResetConfirmation = false

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 主题模式
                themeSelectionSection

                themeModeSection

                // 强调色
                accentColorSection

                // 字体大小
                fontSizeSection

                // 布局密度
                layoutDensitySection

                // 重置按钮
                resetSection
            }
            .padding()
        }
        .navigationTitle(Text("外观"))
        .onAppear(perform: loadData)
        .alert(String(localized: "Reset Appearance Settings"), isPresented: $showResetConfirmation) {
            Button(String(localized: "Cancel"), role: .cancel) { }
            Button(String(localized: "Reset"), role: .destructive) {
                resetToDefaults()
            }
        } message: {
            Text("确定要将所有外观设置重置为默认值吗？")
        }
    }

    // MARK: - View Components

    private var themeSelectionSection: some View {
        GitOKUI.AppSettingsSection(title: String(localized: "Theme")) {
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

                        Text(String(localized: "No themes in this category"))
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

    /// 主题模式设置
    private var themeModeSection: some View {
        GitOKUI.AppSettingsSection(title: String(localized: "Theme Mode")) {
            ForEach(AppAppearanceSettingsStore.ThemeMode.allCases) { mode in
                themeModeRow(mode)
            }
        }
    }

    private func themeModeRow(_ mode: AppAppearanceSettingsStore.ThemeMode) -> some View {
        GitOKUI.AppSettingsRow(isSelected: themeMode == mode, verticalPadding: 10) {
            HStack(spacing: 12) {
                Image(systemName: mode.icon)
                    .foregroundColor(.secondary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: mode.displayName)
                        .font(.system(size: 13))

                    Text(modeDescription(mode))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if themeMode == mode {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 14, weight: .semibold))
                }
            }
        }
        .onTapGesture {
            themeMode = mode
            settings.themeMode = mode
            themeProvider.refreshAppearance()
            logThemeChange(mode)
        }
    }

    private func modeDescription(_ mode: AppAppearanceSettingsStore.ThemeMode) -> String {
        switch mode {
        case .system:
            return String(localized: "Automatically switch with system settings")
        case .light:
            return String(localized: "Always use light appearance")
        case .dark:
            return String(localized: "Always use dark appearance")
        }
    }

    /// 强调色设置
    private var accentColorSection: some View {
        GitOKUI.AppSettingsSection(title: String(localized: "Accent Color")) {
            VStack(alignment: .leading, spacing: 16) {
                Text("选择应用的主要强调色")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(AppAppearanceSettingsStore.AccentColor.allCases) { color in
                        accentColorButton(color)
                    }
                }
                .padding(.horizontal, 8)
            }
            .padding(.vertical, 6)
        }
    }

    private func accentColorButton(_ color: AppAppearanceSettingsStore.AccentColor) -> some View {
        AppSelectionTile(
            isSelected: accentColor == color,
            cornerRadius: 8,
            selectedScale: 1.03,
            selectedBackgroundColor: color.color.opacity(0.10),
            selectedBorderColor: color.color,
            action: {
                accentColor = color
                settings.accentColor = color
                if Self.verbose {
                    os_log("\(Self.t)✅ Changed accent color to: \(color.displayName)")
                }
            }
        ) {
            ZStack {
                Circle()
                    .fill(color.color)
                    .frame(width: 40, height: 40)

                if accentColor == color {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))
                        .shadow(color: .black.opacity(0.3), radius: 2)
                }
            }
            .frame(width: 48, height: 48)
        }
        .frame(width: 48, height: 48)
    }

    /// 字体大小设置
    private var fontSizeSection: some View {
        GitOKUI.AppSettingsSection(title: String(localized: "Font Size")) {
            ForEach(AppAppearanceSettingsStore.FontSize.allCases) { size in
                fontSizeRow(size)
            }
        }
    }

    private func fontSizeRow(_ size: AppAppearanceSettingsStore.FontSize) -> some View {
        GitOKUI.AppSettingsRow(isSelected: fontSize == size, verticalPadding: 10) {
            HStack(spacing: 12) {
                Text("Aa")
                    .font(.system(size: previewFontSize(for: size)))
                    .foregroundColor(.secondary)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: size.displayName)
                        .font(.system(size: 13))

                    Text(verbatim: String.localizedStringWithFormat(NSLocalizedString("Scale: %lld%%", comment: ""), Int64(size.scaleFactor * 100)))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if fontSize == size {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 14, weight: .semibold))
                }
            }
        }
        .onTapGesture {
            fontSize = size
            settings.fontSize = size
            if Self.verbose {
                os_log("\(Self.t)✅ Changed font size to: \(size.displayName)")
            }
        }
    }

    private func previewFontSize(for size: AppAppearanceSettingsStore.FontSize) -> CGFloat {
        let baseSize: CGFloat = 14
        return baseSize * size.scaleFactor
    }

    /// 布局密度设置
    private var layoutDensitySection: some View {
        GitOKUI.AppSettingsSection(title: String(localized: "Layout Density")) {
            ForEach(AppAppearanceSettingsStore.LayoutDensity.allCases) { density in
                layoutDensityRow(density)
            }
        }
    }

    private func layoutDensityRow(_ density: AppAppearanceSettingsStore.LayoutDensity) -> some View {
        GitOKUI.AppSettingsRow(isSelected: layoutDensity == density, verticalPadding: 10) {
            HStack(spacing: 12) {
                Image(systemName: densityIcon(density))
                    .foregroundColor(.secondary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: density.displayName)
                        .font(.system(size: 13))

                    Text(densityDescription(density))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if layoutDensity == density {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 14, weight: .semibold))
                }
            }
        }
        .onTapGesture {
            layoutDensity = density
            settings.layoutDensity = density
            if Self.verbose {
                os_log("\(Self.t)✅ Changed layout density to: \(density.displayName)")
            }
        }
    }

    private func densityDescription(_ density: AppAppearanceSettingsStore.LayoutDensity) -> String {
        switch density {
        case .compact:
            return String(localized: "More compact layout, displays more content")
        case .comfortable:
            return String(localized: "Balanced layout, suitable for most scenarios")
        case .spacious:
            return String(localized: "More spacious layout, visually comfortable")
        }
    }

    private func densityIcon(_ density: AppAppearanceSettingsStore.LayoutDensity) -> String {
        switch density {
        case .compact: return "rectangle.compress.vertical"
        case .comfortable: return "rectangle"
        case .spacious: return "rectangle.expand.vertical"
        }
    }

    /// 重置设置
    private var resetSection: some View {
        GitOKUI.AppSettingsSection(title: String(localized: "Reset")) {
            AppButton(
                String(localized: "重置所有外观设置"),
                systemImage: "arrow.counterclockwise",
                style: .destructive,
                size: .small
            ) {
                showResetConfirmation = true
            }
        }
    }

    // MARK: - Actions

    private func loadData() {
        themeMode = settings.themeMode
        selectedThemeId = themeProvider.currentThemeId
        accentColor = settings.accentColor
        fontSize = settings.fontSize
        layoutDensity = settings.layoutDensity

        if Self.verbose {
            os_log("\(Self.t)📋 Loaded appearance settings:")
            os_log("\(Self.t)  - Theme: \(themeMode.displayName)")
            os_log("\(Self.t)  - Accent: \(accentColor.displayName)")
            os_log("\(Self.t)  - Font: \(fontSize.displayName)")
            os_log("\(Self.t)  - Density: \(layoutDensity.displayName)")
        }
    }

    private func resetToDefaults() {
        settings.resetToDefaults()
        themeProvider.reloadThemes()
        loadData()

        if Self.verbose {
            os_log("\(Self.t)♻️ Reset all appearance settings to defaults")
        }
    }

    private func logThemeChange(_ mode: AppAppearanceSettingsStore.ThemeMode) {
        if Self.verbose {
            os_log("\(Self.t)✅ Changed theme mode to: \(mode.displayName)")
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
            return String(localized: "All")
        case .dark:
            return String(localized: "Black")
        case .light:
            return String(localized: "Light")
        case .system:
            return String(localized: "System")
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
