import Foundation
import SwiftUI

/// 应用外观设置存储
class AppAppearanceSettingsStore: ObservableObject {
    static let shared = AppAppearanceSettingsStore()

    // MARK: - UserDefaults Keys

    private let themeModeKey = "GitOK_Appearance_ThemeMode"
    private let selectedThemeIdKey = "GitOK_Appearance_SelectedThemeId"
    private let accentColorKey = "GitOK_Appearance_AccentColor"
    private let fontSizeKey = "GitOK_Appearance_FontSize"
    private let layoutDensityKey = "GitOK_Appearance_LayoutDensity"

    // MARK: - Theme Mode

    /// 主题模式
    enum ThemeMode: String, CaseIterable, Identifiable {
        case system = "system"
        case light = "light"
        case dark = "dark"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .system: return String(localized: "Follow System", table: "Core")
            case .light: return String(localized: "Light Mode", table: "Core")
            case .dark: return String(localized: "Dark Mode", table: "Core")
            }
        }

        var icon: String {
            switch self {
            case .system: return "desktopcomputer"
            case .light: return "sun.max"
            case .dark: return "moon"
            }
        }

        @available(macOS 13.0, *)
        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
            }
        }
    }

    /// 当前主题模式
    var themeMode: ThemeMode {
        get {
            let rawValue = UserDefaults.standard.string(forKey: themeModeKey) ?? ThemeMode.system.rawValue
            return ThemeMode(rawValue: rawValue) ?? .system
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: themeModeKey)
        }
    }

    var selectedThemeId: String? {
        get {
            UserDefaults.standard.string(forKey: selectedThemeIdKey)
        }
        set {
            if let newValue {
                UserDefaults.standard.set(newValue, forKey: selectedThemeIdKey)
            } else {
                UserDefaults.standard.removeObject(forKey: selectedThemeIdKey)
            }
        }
    }

    // MARK: - Accent Color

    /// 强调色
    enum AccentColor: String, CaseIterable, Identifiable {
        case blue = "blue"
        case purple = "purple"
        case pink = "pink"
        case red = "red"
        case orange = "orange"
        case yellow = "yellow"
        case green = "green"
        case indigo = "indigo"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .blue: return String(localized: "Blue", table: "Core")
            case .purple: return String(localized: "Purple", table: "Core")
            case .pink: return String(localized: "Pink", table: "Core")
            case .red: return String(localized: "Red", table: "Core")
            case .orange: return String(localized: "Orange", table: "Core")
            case .yellow: return String(localized: "Yellow", table: "Core")
            case .green: return String(localized: "Green", table: "Core")
            case .indigo: return String(localized: "Indigo", table: "Core")
            }
        }

        var color: Color {
            switch self {
            case .blue: return .blue
            case .purple: return .purple
            case .pink: return .pink
            case .red: return .red
            case .orange: return .orange
            case .yellow: return .yellow
            case .green: return .green
            case .indigo: return .indigo
            }
        }
    }

    /// 当前强调色
    var accentColor: AccentColor {
        get {
            let rawValue = UserDefaults.standard.string(forKey: accentColorKey) ?? AccentColor.blue.rawValue
            return AccentColor(rawValue: rawValue) ?? .blue
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: accentColorKey)
        }
    }

    // MARK: - Font Size

    /// 字体大小
    enum FontSize: String, CaseIterable, Identifiable {
        case small = "small"
        case medium = "medium"
        case large = "large"
        case extraLarge = "extraLarge"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .small: return String(localized: "Small", table: "Core")
            case .medium: return String(localized: "Medium", table: "Core")
            case .large: return String(localized: "Large", table: "Core")
            case .extraLarge: return String(localized: "Extra Large", table: "Core")
            }
        }

        var scaleFactor: CGFloat {
            switch self {
            case .small: return 0.9
            case .medium: return 1.0
            case .large: return 1.1
            case .extraLarge: return 1.2
            }
        }
    }

    /// 当前字体大小
    var fontSize: FontSize {
        get {
            let rawValue = UserDefaults.standard.string(forKey: fontSizeKey) ?? FontSize.medium.rawValue
            return FontSize(rawValue: rawValue) ?? .medium
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: fontSizeKey)
        }
    }

    // MARK: - Layout Density

    /// 布局密度
    enum LayoutDensity: String, CaseIterable, Identifiable {
        case compact = "compact"
        case comfortable = "comfortable"
        case spacious = "spacious"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .compact: return String(localized: "Compact", table: "Core")
            case .comfortable: return String(localized: "Comfortable", table: "Core")
            case .spacious: return String(localized: "Spacious", table: "Core")
            }
        }

        var spacingMultiplier: CGFloat {
            switch self {
            case .compact: return 0.8
            case .comfortable: return 1.0
            case .spacious: return 1.2
            }
        }
    }

    /// 当前布局密度
    var layoutDensity: LayoutDensity {
        get {
            let rawValue = UserDefaults.standard.string(forKey: layoutDensityKey) ?? LayoutDensity.comfortable.rawValue
            return LayoutDensity(rawValue: rawValue) ?? .comfortable
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: layoutDensityKey)
        }
    }

    // MARK: - Reset

    /// 重置所有设置为默认值
    func resetToDefaults() {
        UserDefaults.standard.removeObject(forKey: themeModeKey)
        UserDefaults.standard.removeObject(forKey: selectedThemeIdKey)
        UserDefaults.standard.removeObject(forKey: accentColorKey)
        UserDefaults.standard.removeObject(forKey: fontSizeKey)
        UserDefaults.standard.removeObject(forKey: layoutDensityKey)
    }

    private init() {}
}
