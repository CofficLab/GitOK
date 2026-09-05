import Foundation
import AppKit
import Testing
@testable import ProviderTheme

@MainActor
@Suite("ProviderTheme Edge Cases")
struct ProviderThemeEdgeCaseTests {

    // MARK: - Helpers

    private func makeTheme(id: String, sortOrder: Int = 100, appearanceKind: ThemeAppearanceKind = .system) -> LumiTheme {
        LumiTheme(
            id: id,
            sortOrder: sortOrder,
            displayName: id,
            iconName: "circle",
            iconColor: ThemeHexPair(hex: "007AFF"),
            appearanceKind: appearanceKind,
            palette: BuiltinThemes.system.palette
        )
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ProviderThemeEdgeTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func makeProvider(builtinThemes: [LumiTheme] = BuiltinThemes.all) throws -> DefaultThemeProviding {
        DefaultThemeProviding(
            storageDirectory: try makeTemporaryDirectory(),
            builtinThemes: builtinThemes
        )
    }

    private func writeSelectionPlist(_ themeID: String?, to directory: URL) throws {
        let url = directory.appendingPathComponent("theme-selection.plist", isDirectory: false)
        let plist: [String: String] = themeID.map { ["selectedThemeID": $0] } ?? [:]
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try data.write(to: url, options: .atomic)
    }

    // MARK: - Selection no-op / notify semantics

    @Test("重复选中同一主题为 no-op，不触发任何通知")
    func selectSameThemeIsNoop() throws {
        let provider = try makeProvider()
        var eventCount = 0
        let handle = provider.addObserver { _ in eventCount += 1 }
        defer { handle.cancel() }

        try provider.selectTheme(id: "lumi")

        #expect(eventCount == 0)
    }

    @Test("注册主题触发 themesChanged 通知")
    func registerThemeNotifies() throws {
        let provider = try makeProvider(builtinThemes: [])
        var events: [ThemeProvidingEvent] = []
        let handle = provider.addObserver { events.append($0) }
        defer { handle.cancel() }

        provider.registerTheme(makeTheme(id: "a"))

        #expect(events.count == 1)
        if case .themesChanged = events[0] {} else { Issue.record("期望 themesChanged，得到 \(events[0])") }
    }

    @Test("注销非选中主题仅触发 themesChanged，选中不变")
    func unregisterNonSelectedKeepsSelection() throws {
        let provider = try makeProvider()
        try provider.selectTheme(id: "lumi-dark")
        var themesChangedCount = 0
        var selectionChangedCount = 0
        let handle = provider.addObserver { event in
            switch event {
            case .themesChanged: themesChangedCount += 1
            case .selectionChanged: selectionChangedCount += 1
            }
        }
        defer { handle.cancel() }

        provider.unregisterTheme(id: "lumi-light")

        #expect(themesChangedCount == 1)
        #expect(selectionChangedCount == 0)
        #expect(provider.selectedThemeId == "lumi-dark")
    }

    // MARK: - Replace-all fallback order

    @Test("全量替换时持久化偏好优先于第一个主题")
    func replaceAllPrefersPersisted() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let provider = DefaultThemeProviding(storageDirectory: directory, builtinThemes: [])
        provider.registerTheme(makeTheme(id: "old", sortOrder: 100))
        // 初始选中 old；随后外部写入持久化偏好 lumi-dark。
        try provider.selectTheme(id: "old")
        try writeSelectionPlist("lumi-dark", to: directory)

        try provider.replaceAllThemes([
            makeTheme(id: "lumi-dark", sortOrder: 100),
            makeTheme(id: "fresh", sortOrder: 200),
        ])

        // 原选中 old 已不存在 → 回退到持久化的 lumi-dark。
        #expect(provider.selectedThemeId == "lumi-dark")
    }

    // MARK: - Storage directory injection

    @Test("注入存储目录后恢复持久化选中并通知")
    func setStorageDirectoryRestoresSelection() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try writeSelectionPlist("lumi-dark", to: directory)

        let provider = try makeProvider()
        var selectionEvents: [String?] = []
        let handle = provider.addObserver { event in
            if case let .selectionChanged(id) = event { selectionEvents.append(id) }
        }
        defer { handle.cancel() }

        provider.setStorageDirectory(directory)

        #expect(provider.selectedThemeId == "lumi-dark")
        #expect(selectionEvents == ["lumi-dark"])
    }

    @Test("持久化文件损坏时回退到第一个主题")
    func corruptedSelectionFileFallsBack() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("theme-selection.plist", isDirectory: false)
        try Data("not a plist".utf8).write(to: url)

        let provider = DefaultThemeProviding(storageDirectory: directory)

        #expect(provider.selectedThemeId == "lumi")
    }

    // MARK: - Hex color resolution

    @Test("十六进制颜色按显式外观解析（含 # 前缀与 8 位 AARRGGBB）")
    func hexColorResolvesExplicitScheme() {
        let pair = ThemeHexPair(light: "#FF0000", dark: "8000FF00")

        let light = NSColor(pair.color(colorScheme: .light)).usingColorSpace(.sRGB)
        #expect(abs((light?.redComponent ?? -1) - 1.0) < 0.01)
        #expect(abs((light?.greenComponent ?? -1)) < 0.01)

        let dark = NSColor(pair.color(colorScheme: .dark)).usingColorSpace(.sRGB)
        #expect(abs((dark?.greenComponent ?? -1) - 1.0) < 0.01)
        #expect(abs((dark?.alphaComponent ?? -1) - 0.5) < 0.01)
    }

    @Test("无显式外观时按系统当前外观解析")
    func hexColorFallsBackToSystem() {
        // 触发 SystemAppearanceResolver 需要 AppKit 应用实例。
        _ = NSApplication.shared
        let pair = ThemeHexPair(light: "0000FF", dark: "FF0000")
        // 仅验证解析不崩溃且返回非空颜色；实际明暗取决于测试机系统外观。
        let color = pair.color()
        let nsColor = NSColor(color).usingColorSpace(.sRGB)
        #expect(nsColor != nil)
    }

    // MARK: - Theme model

    @Test("compactName 默认回退到 displayName")
    func compactNameDefaultsToDisplayName() {
        _ = NSApplication.shared
        let theme = LumiTheme(
            id: "x",
            displayName: "Custom Name",
            iconName: "circle",
            iconColor: ThemeHexPair(hex: "000000"),
            appearanceKind: .system,
            palette: BuiltinThemes.system.palette
        )
        #expect(theme.compactName == "Custom Name")
        #expect(theme.resolvedIconColor.description.isEmpty == false)
    }

    @Test("followsSystemAppearance 跟随选中主题外观类型")
    func followsSystemAppearanceByKind() throws {
        let provider = try makeProvider(builtinThemes: [])

        for kind in ThemeAppearanceKind.allCases {
            #expect(kind.id == kind.rawValue)
            let theme = makeTheme(id: "theme-\(kind.rawValue)", appearanceKind: kind)
            provider.registerTheme(theme)
            try provider.selectTheme(id: theme.id)
            #expect(provider.followsSystemAppearance == (kind == .system))
        }
    }
}
