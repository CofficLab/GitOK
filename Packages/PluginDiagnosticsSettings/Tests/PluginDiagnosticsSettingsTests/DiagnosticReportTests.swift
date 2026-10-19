import Foundation
import Testing

@testable import PluginDiagnosticsSettings

@Suite("DiagnosticReport")
struct DiagnosticReportTests {

    /// 构造一个带自定义 Info.plist 的 Bundle，供版本号相关断言使用。
    ///
    /// 临时目录在函数返回后即被清理；`Bundle` 读取 Info.plist 发生在调用方断言之前，
    /// 因此这里直接返回 Bundle 而非目录。
    private func makeBundle(infoDictionary: [String: Any]) throws -> Bundle {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("DiagnosticsTests-\(UUID().uuidString).bundle")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        let data = try PropertyListSerialization.data(
            fromPropertyList: infoDictionary,
            format: .xml,
            options: 0
        )
        try data.write(to: url.appendingPathComponent("Info.plist"))
        return try #require(Bundle(url: url))
    }

    // MARK: 报告文本

    @Test("报告包含标题与四行内容")
    func reportHasExpectedShape() throws {
        let bundle = try makeBundle(infoDictionary: [:])

        let report = DiagnosticReport.text(
            bundle: bundle,
            operatingSystemVersion: "macOS 14.0"
        )
        let lines = report.split(separator: "\n", omittingEmptySubsequences: false)

        #expect(lines.count == 4)
        #expect(lines[0] == "GitOK Diagnostics")
        #expect(lines[1].hasPrefix("App Version:"))
        #expect(lines[2].hasPrefix("Build:"))
        #expect(lines[3] == "macOS: macOS 14.0")
    }

    @Test("版本号与构建号存在时写入报告")
    func includesVersionAndBuild() throws {
        let bundle = try makeBundle(infoDictionary: [
            "CFBundleShortVersionString": "1.2.3",
            "CFBundleVersion": "456"
        ])

        let report = DiagnosticReport.text(bundle: bundle, operatingSystemVersion: "macOS 14.0")

        #expect(report.contains("App Version: 1.2.3"))
        #expect(report.contains("Build: 456"))
    }

    @Test("版本号缺失时以 - 占位")
    func placeholderWhenVersionMissing() throws {
        let bundle = try makeBundle(infoDictionary: ["CFBundleVersion": "456"])

        let report = DiagnosticReport.text(bundle: bundle, operatingSystemVersion: "macOS 14.0")

        #expect(report.contains("App Version: -"))
        #expect(report.contains("Build: 456"))
    }

    @Test("构建号缺失时以 - 占位")
    func placeholderWhenBuildMissing() throws {
        let bundle = try makeBundle(infoDictionary: ["CFBundleShortVersionString": "1.2.3"])

        let report = DiagnosticReport.text(bundle: bundle, operatingSystemVersion: "macOS 14.0")

        #expect(report.contains("App Version: 1.2.3"))
        #expect(report.contains("Build: -"))
    }

    @Test("两项都缺失时均以 - 占位")
    func placeholderWhenBothMissing() throws {
        let bundle = try makeBundle(infoDictionary: [:])

        let report = DiagnosticReport.text(bundle: bundle, operatingSystemVersion: "macOS 14.0")

        #expect(report.contains("App Version: -"))
        #expect(report.contains("Build: -"))
    }

    @Test("版本号类型非字符串时同样以 - 占位")
    func placeholderWhenVersionIsNotString() throws {
        let bundle = try makeBundle(infoDictionary: [
            "CFBundleShortVersionString": 123,
            "CFBundleVersion": "456"
        ])

        let report = DiagnosticReport.text(bundle: bundle, operatingSystemVersion: "macOS 14.0")

        #expect(report.contains("App Version: -"))
        #expect(report.contains("Build: 456"))
    }

    @Test("系统版本原样写入")
    func includesOperatingSystemVersion() throws {
        let bundle = try makeBundle(infoDictionary: [:])

        let report = DiagnosticReport.text(bundle: bundle, operatingSystemVersion: "macOS 15.3 (Build 24D81)")

        #expect(report.contains("macOS: macOS 15.3 (Build 24D81)"))
    }

    @Test("默认调用不会崩溃并生成非空报告")
    func defaultArgumentsProduceReport() {
        let report = DiagnosticReport.text()

        #expect(report.hasPrefix("GitOK Diagnostics"))
        #expect(report.contains("macOS: "))
    }

    @Test("常量与键名保持稳定")
    func constants() {
        #expect(DiagnosticReport.title == "GitOK Diagnostics")
        #expect(DiagnosticReport.placeholder == "-")
        #expect(DiagnosticReport.applicationDirectoryName == "GitOK")
        #expect(DiagnosticReport.versionKey == "CFBundleShortVersionString")
        #expect(DiagnosticReport.buildKey == "CFBundleVersion")
    }

    // MARK: Application Support 路径

    @Test("支持目录存在时追加应用子目录")
    func appendsApplicationDirectory() throws {
        let base = URL(fileURLWithPath: "/Users/test/Library/Application Support", isDirectory: true)

        let url = DiagnosticReport.applicationSupportURL(base: base)

        let resolved = try #require(url)
        #expect(resolved.lastPathComponent == "GitOK")
        #expect(resolved.deletingLastPathComponent() == base)
    }

    @Test("支持目录为 nil 时返回 nil")
    func returnsNilWhenBaseIsNil() {
        #expect(DiagnosticReport.applicationSupportURL(base: nil) == nil)
    }
}
