import Foundation
import MagicKit
import OSLog
import SwiftUI

/// 应用外观设置视图
struct AppAppearanceSettingView: View, SuperLog {
    /// emoji 标识符
    nonisolated static let emoji = "🎨"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    @StateObject private var settings = AppAppearanceSettingsStore.shared

    /// 主题模式
    @State private var themeMode: AppAppearanceSettingsStore.ThemeMode = .system

    /// 强调色
    @State private var accentColor: AppAppearanceSettingsStore.AccentColor = .blue

    /// 字体大小
    @State private var fontSize: AppAppearanceSettingsStore.FontSize = .medium

    /// 布局密度
    @State private var layoutDensity: AppAppearanceSettingsStore.LayoutDensity = .comfortable

    /// 显示重置确认对话框
    @State private var showResetConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 主题模式
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
        .navigationTitle("外观")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("完成") {
                    // 关闭设置视图
                    NotificationCenter.default.post(name: .didSaveGitUserConfig, object: nil)
                }
            }
        }
        .onAppear(perform: loadData)
        .alert("重置外观设置", isPresented: $showResetConfirmation) {
            Button("取消", role: .cancel) { }
            Button("重置", role: .destructive) {
                resetToDefaults()
            }
        } message: {
            Text("确定要将所有外观设置重置为默认值吗？")
        }
    }

    // MARK: - View Components

    /// 主题模式设置
    private var themeModeSection: some View {
        MagicSettingSection(title: "主题模式", titleAlignment: .leading) {
            VStack(spacing: 0) {
                ForEach(AppAppearanceSettingsStore.ThemeMode.allCases) { mode in
                    themeModeRow(mode)
                    if mode != AppAppearanceSettingsStore.ThemeMode.allCases.last {
                        Divider()
                    }
                }
            }
        }
    }

    private func themeModeRow(_ mode: AppAppearanceSettingsStore.ThemeMode) -> some View {
        HStack(spacing: 12) {
            Image(systemName: mode.icon)
                .foregroundColor(.secondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(mode.displayName)
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
        .contentShape(Rectangle())
        .onTapGesture {
            themeMode = mode
            settings.themeMode = mode
            logThemeChange(mode)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    private func modeDescription(_ mode: AppAppearanceSettingsStore.ThemeMode) -> String {
        switch mode {
        case .system:
            return "跟随系统设置自动切换"
        case .light:
            return "始终使用浅色外观"
        case .dark:
            return "始终使用深色外观"
        }
    }

    /// 强调色设置
    private var accentColorSection: some View {
        MagicSettingSection(title: "强调色", titleAlignment: .leading) {
            VStack(alignment: .leading, spacing: 16) {
                Text("选择应用的主要强调色")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

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
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
        }
    }

    private func accentColorButton(_ color: AppAppearanceSettingsStore.AccentColor) -> some View {
        Button {
            accentColor = color
            settings.accentColor = color
            if Self.verbose {
                os_log("\(Self.t)✅ Changed accent color to: \(color.displayName)")
            }
        } label: {
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
        }
        .buttonStyle(.plain)
    }

    /// 字体大小设置
    private var fontSizeSection: some View {
        MagicSettingSection(title: "字体大小", titleAlignment: .leading) {
            VStack(spacing: 0) {
                ForEach(AppAppearanceSettingsStore.FontSize.allCases) { size in
                    fontSizeRow(size)
                    if size != AppAppearanceSettingsStore.FontSize.allCases.last {
                        Divider()
                    }
                }
            }
        }
    }

    private func fontSizeRow(_ size: AppAppearanceSettingsStore.FontSize) -> some View {
        HStack(spacing: 12) {
            Text("Aa")
                .font(.system(size: previewFontSize(for: size)))
                .foregroundColor(.secondary)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(size.displayName)
                    .font(.system(size: 13))

                Text("缩放比例: \(Int(size.scaleFactor * 100))%")
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
        .contentShape(Rectangle())
        .onTapGesture {
            fontSize = size
            settings.fontSize = size
            if Self.verbose {
                os_log("\(Self.t)✅ Changed font size to: \(size.displayName)")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    private func previewFontSize(for size: AppAppearanceSettingsStore.FontSize) -> CGFloat {
        let baseSize: CGFloat = 14
        return baseSize * size.scaleFactor
    }

    /// 布局密度设置
    private var layoutDensitySection: some View {
        MagicSettingSection(title: "布局密度", titleAlignment: .leading) {
            VStack(spacing: 0) {
                ForEach(AppAppearanceSettingsStore.LayoutDensity.allCases) { density in
                    layoutDensityRow(density)
                    if density != AppAppearanceSettingsStore.LayoutDensity.allCases.last {
                        Divider()
                    }
                }
            }
        }
    }

    private func layoutDensityRow(_ density: AppAppearanceSettingsStore.LayoutDensity) -> some View {
        HStack(spacing: 12) {
            Image(systemName: densityIcon(density))
                .foregroundColor(.secondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(density.displayName)
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
        .contentShape(Rectangle())
        .onTapGesture {
            layoutDensity = density
            settings.layoutDensity = density
            if Self.verbose {
                os_log("\(Self.t)✅ Changed layout density to: \(density.displayName)")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    private func densityDescription(_ density: AppAppearanceSettingsStore.LayoutDensity) -> String {
        switch density {
        case .compact:
            return "更紧凑的布局，显示更多内容"
        case .comfortable:
            return "平衡的布局，适合大多数场景"
        case .spacious:
            return "更宽松的布局，视觉更舒适"
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
        MagicSettingSection(title: "重置", titleAlignment: .leading) {
            Button(role: .destructive) {
                showResetConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("重置所有外观设置")
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Actions

    private func loadData() {
        themeMode = settings.themeMode
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

// MARK: - Preview

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
