import Foundation
import Testing

@testable import PluginAboutSettings

@Suite("AppInfo")
struct AppInfoTests {

    /// 构造一个带自定义 Info.plist 的 Bundle，供字段读取断言使用。
    private func makeBundle(infoDictionary: [String: Any]) throws -> Bundle {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("AboutSettingsTests-\(UUID().uuidString).bundle")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        let data = try PropertyListSerialization.data(
            fromPropertyList: infoDictionary,
            format: .xml,
            options: 0
        )
        try data.write(to: url.appendingPathComponent("Info.plist"))
        return try #require(Bundle(url: url))
    }

    // MARK: 字段齐全

    @Test("Info.plist 字段齐全时全部读取成功")
    func readsAllFields() throws {
        let bundle = try makeBundle(infoDictionary: [
            "CFBundleName": "GitOK",
            "CFBundleShortVersionString": "2.4.1",
            "CFBundleVersion": "917"
        ])

        let info = AppInfo(bundle: bundle)

        #expect(info.name == "GitOK")
        #expect(info.version == "2.4.1")
        #expect(info.build == "917")
    }

    @Test("bundleIdentifier 从 bundle 读取")
    func readsBundleIdentifier() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("AboutID-\(UUID().uuidString).bundle")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        let data = try PropertyListSerialization.data(
            fromPropertyList: ["CFBundleIdentifier": "com.coffic.gitok.test"],
            format: .xml,
            options: 0
        )
        try data.write(to: url.appendingPathComponent("Info.plist"))
        let bundle = try #require(Bundle(url: url))

        let info = AppInfo(bundle: bundle)

        #expect(info.bundleIdentifier == "com.coffic.gitok.test")
    }

    // MARK: 字段缺失

    @Test("应用名缺失时回落到 GitOK")
    func fallsBackToDefaultName() throws {
        let bundle = try makeBundle(infoDictionary: [:])

        let info = AppInfo(bundle: bundle)

        #expect(info.name == "GitOK")
    }

    @Test("版本号缺失时回落到 -")
    func fallsBackWhenVersionMissing() throws {
        let bundle = try makeBundle(infoDictionary: [:])

        let info = AppInfo(bundle: bundle)

        #expect(info.version == "-")
    }

    @Test("构建号缺失时回落到 -")
    func fallsBackWhenBuildMissing() throws {
        let bundle = try makeBundle(infoDictionary: [:])

        let info = AppInfo(bundle: bundle)

        #expect(info.build == "-")
    }

    @Test("仅提供部分字段时其余仍回落")
    func fallsBackForMissingFieldsOnly() throws {
        let bundle = try makeBundle(infoDictionary: ["CFBundleShortVersionString": "1.0.0"])

        let info = AppInfo(bundle: bundle)

        #expect(info.version == "1.0.0")
        #expect(info.name == "GitOK")
        #expect(info.build == "-")
    }

    // MARK: 类型不符

    @Test("版本号为数字时视为缺失并回落")
    func fallsBackWhenVersionIsNotString() throws {
        let bundle = try makeBundle(infoDictionary: [
            "CFBundleShortVersionString": 240,
            "CFBundleVersion": "917"
        ])

        let info = AppInfo(bundle: bundle)

        #expect(info.version == "-")
        #expect(info.build == "917")
    }

    @Test("构建号为数字时视为缺失并回落")
    func fallsBackWhenBuildIsNotString() throws {
        let bundle = try makeBundle(infoDictionary: [
            "CFBundleName": "GitOK",
            "CFBundleVersion": 917
        ])

        let info = AppInfo(bundle: bundle)

        #expect(info.build == "-")
        #expect(info.name == "GitOK")
    }

    @Test("应用名为非字符串时回落到 GitOK")
    func fallsBackWhenNameIsNotString() throws {
        let bundle = try makeBundle(infoDictionary: ["CFBundleName": ["unexpected": "array"]])

        let info = AppInfo(bundle: bundle)

        #expect(info.name == "GitOK")
    }

    // MARK: 直接构造与常量

    @Test("支持直接构造全部字段")
    func directInit() {
        let info = AppInfo(name: "App", version: "1.2", build: "3", bundleIdentifier: "com.x")

        #expect(info.name == "App")
        #expect(info.version == "1.2")
        #expect(info.build == "3")
        #expect(info.bundleIdentifier == "com.x")
    }

    @Test("键名与占位常量保持稳定")
    func constants() {
        #expect(AppInfo.nameKey == "CFBundleName")
        #expect(AppInfo.versionKey == "CFBundleShortVersionString")
        #expect(AppInfo.buildKey == "CFBundleVersion")
        #expect(AppInfo.defaultName == "GitOK")
        #expect(AppInfo.placeholder == "-")
    }

    @Test("支持相等比较")
    func equatable() {
        let a = AppInfo(name: "GitOK", version: "1", build: "2", bundleIdentifier: "com.x")
        let b = AppInfo(name: "GitOK", version: "1", build: "2", bundleIdentifier: "com.x")
        let c = AppInfo(name: "Other", version: "1", build: "2", bundleIdentifier: "com.x")

        #expect(a == b)
        #expect(a != c)
    }

    @Test("默认参数从主 bundle 读取且不崩溃")
    func defaultBundleReads() {
        // 测试环境的主 bundle 通常没有 App Info.plist 字段，应全部走回落
        let info = AppInfo()

        #expect(info.name.isEmpty == false)
        #expect(info.version.isEmpty == false)
        #expect(info.build.isEmpty == false)
        #expect(info.bundleIdentifier.isEmpty == false)
    }
}
