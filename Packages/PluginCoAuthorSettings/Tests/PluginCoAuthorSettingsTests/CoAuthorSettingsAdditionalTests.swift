import Foundation
import Testing
@testable import PluginCoAuthorSettings
import KernelCore

@Suite("CoAuthorSettingsLocalization Parsing")
@MainActor
struct CoAuthorSettingsLocalizationTests {

    private enum TestError: Error { case bundleCreationFailed }

    private func makeBundle(catalog: [String: Any]) throws -> Bundle {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("CoAuthorLoc-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let data = try JSONSerialization.data(withJSONObject: catalog)
        try data.write(to: dir.appendingPathComponent("Localizable.xcstrings"))
        guard let bundle = Bundle(path: dir.path) else { throw TestError.bundleCreationFailed }
        return bundle
    }

    @Test("returns key when no catalog file exists")
    func returnsKeyWhenNoFile() {
        let emptyDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("CoAuthorLocEmpty-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: emptyDir, withIntermediateDirectories: true)
        let bundle = Bundle(path: emptyDir.path)!
        #expect(CoAuthorSettingsLocalization.string("Missing", bundle: bundle) == "Missing")
    }

    @Test("prefers zh-Hans translation")
    func prefersZhHans() throws {
        let catalog: [String: Any] = [
            "strings": [
                "Co-Authors": [
                    "localizations": [
                        "zh-Hans": ["stringUnit": ["state": "translated", "value": "协作者"]],
                        "en": ["stringUnit": ["state": "translated", "value": "Co-Authors"]],
                    ],
                ],
            ],
        ]
        let bundle = try makeBundle(catalog: catalog)
        #expect(CoAuthorSettingsLocalization.string("Co-Authors", bundle: bundle) == "协作者")
    }

    @Test("falls back to en when zh-Hans absent")
    func fallsBackToEn() throws {
        let catalog: [String: Any] = [
            "strings": [
                "Co-Authors": [
                    "localizations": [
                        "en": ["stringUnit": ["state": "translated", "value": "Co-Authors"]],
                    ],
                ],
            ],
        ]
        let bundle = try makeBundle(catalog: catalog)
        #expect(CoAuthorSettingsLocalization.string("Co-Authors", bundle: bundle) == "Co-Authors")
    }

    @Test("returns key when entry has no localizations")
    func returnsKeyWhenNoLocalizations() throws {
        let catalog: [String: Any] = [
            "strings": [
                "Orphan": ["state": "translated"],
            ],
        ]
        let bundle = try makeBundle(catalog: catalog)
        #expect(CoAuthorSettingsLocalization.string("Orphan", bundle: bundle) == "Orphan")
    }
}

@Suite("CoAuthorSettingsPlugin Lifecycle")
@MainActor
struct CoAuthorSettingsPluginLifecycleTests {

    @Test("onBoot with missing SettingViewProviding returns early")
    func onBootMissingSettingView() throws {
        let kernel = KernelCoreContainer()
        let plugin = CoAuthorSettingsPlugin()
        try plugin.onBoot(kernel: kernel)
        // 不崩溃即可。
    }

    @Test("onRegister/onUnregister with empty kernel are no-ops")
    func onRegisterNoop() throws {
        let kernel = KernelCoreContainer()
        let plugin = CoAuthorSettingsPlugin()
        try plugin.onRegister(kernel: kernel)
        try plugin.onUnregister(kernel: kernel)
    }

    @Test("onShutdown with empty kernel is a no-op")
    func onShutdownNoop() throws {
        let kernel = KernelCoreContainer()
        let plugin = CoAuthorSettingsPlugin()
        try plugin.onShutdown(kernel: kernel)
    }
}
