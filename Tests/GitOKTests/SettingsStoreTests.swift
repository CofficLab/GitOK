import XCTest

final class SettingsStoreTests: XCTestCase {
    private let pluginSettingsKey = "GitOK_PluginSettings"
    private let themeModeKey = "GitOK_Appearance_ThemeMode"
    private let accentColorKey = "GitOK_Appearance_AccentColor"
    private let fontSizeKey = "GitOK_Appearance_FontSize"
    private let layoutDensityKey = "GitOK_Appearance_LayoutDensity"

    override func setUp() {
        super.setUp()
        clearSettings()
    }

    override func tearDown() {
        clearSettings()
        super.tearDown()
    }

    func testPluginSettingsStoreReturnsDefaultUntilUserConfiguresPlugin() {
        let pluginID = "test.plugin.\(UUID().uuidString)"
        let store = PluginSettingsStore.shared

        XCTAssertFalse(store.hasUserConfigured(pluginID))
        XCTAssertTrue(store.isPluginEnabled(pluginID, defaultEnabled: true))
        XCTAssertFalse(store.isPluginEnabled(pluginID, defaultEnabled: false))
    }

    func testPluginSettingsStorePersistsConfiguredValueInMemoryAndDefaults() {
        let pluginID = "test.plugin.\(UUID().uuidString)"
        let store = PluginSettingsStore.shared

        store.setPluginEnabled(pluginID, enabled: false)

        XCTAssertTrue(store.hasUserConfigured(pluginID))
        XCTAssertFalse(store.isPluginEnabled(pluginID, defaultEnabled: true))

        let persisted = UserDefaults.standard.dictionary(forKey: pluginSettingsKey) as? [String: Bool]
        XCTAssertEqual(persisted?[pluginID], false)
    }

    func testAppAppearanceSettingsDefaultsAreReturnedWhenNothingStored() {
        let store = AppAppearanceSettingsStore.shared

        XCTAssertEqual(store.themeMode, .system)
        XCTAssertEqual(store.accentColor, .blue)
        XCTAssertEqual(store.fontSize, .medium)
        XCTAssertEqual(store.layoutDensity, .comfortable)
    }

    func testAppAppearanceSettingsFallbackToDefaultsForInvalidStoredValues() {
        UserDefaults.standard.set("invalid", forKey: themeModeKey)
        UserDefaults.standard.set("invalid", forKey: accentColorKey)
        UserDefaults.standard.set("invalid", forKey: fontSizeKey)
        UserDefaults.standard.set("invalid", forKey: layoutDensityKey)

        let store = AppAppearanceSettingsStore.shared

        XCTAssertEqual(store.themeMode, .system)
        XCTAssertEqual(store.accentColor, .blue)
        XCTAssertEqual(store.fontSize, .medium)
        XCTAssertEqual(store.layoutDensity, .comfortable)
    }

    func testAppAppearanceSettingsRoundTripAndResetToDefaults() {
        let store = AppAppearanceSettingsStore.shared

        store.themeMode = .dark
        store.accentColor = .green
        store.fontSize = .large
        store.layoutDensity = .compact

        XCTAssertEqual(store.themeMode, .dark)
        XCTAssertEqual(store.accentColor, .green)
        XCTAssertEqual(store.fontSize, .large)
        XCTAssertEqual(store.layoutDensity, .compact)

        store.resetToDefaults()

        XCTAssertEqual(store.themeMode, .system)
        XCTAssertEqual(store.accentColor, .blue)
        XCTAssertEqual(store.fontSize, .medium)
        XCTAssertEqual(store.layoutDensity, .comfortable)
        XCTAssertNil(UserDefaults.standard.object(forKey: themeModeKey))
        XCTAssertNil(UserDefaults.standard.object(forKey: accentColorKey))
        XCTAssertNil(UserDefaults.standard.object(forKey: fontSizeKey))
        XCTAssertNil(UserDefaults.standard.object(forKey: layoutDensityKey))
    }

    private func clearSettings() {
        UserDefaults.standard.removeObject(forKey: pluginSettingsKey)
        UserDefaults.standard.removeObject(forKey: themeModeKey)
        UserDefaults.standard.removeObject(forKey: accentColorKey)
        UserDefaults.standard.removeObject(forKey: fontSizeKey)
        UserDefaults.standard.removeObject(forKey: layoutDensityKey)
    }
}
