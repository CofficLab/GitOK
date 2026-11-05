import Foundation
import XCTest
@testable import KitGitOKCLI

/// `CLIScriptLanguage` 的语言解析与文案切换测试。
final class CLIScriptLanguageTests: XCTestCase {
    /// 英文脚本不含中文提示。
    func testEnglishScriptHasNoChineseText() {
        let contents = CLIScriptBuilder.scriptContents(language: .english)
        XCTAssertFalse(contents.contains("未找到"), "英文脚本不应包含中文提示")
        XCTAssertFalse(contents.contains("路径不存在"), "英文脚本不应包含中文提示")
        XCTAssertTrue(contents.contains("GitOK.app not found"))
    }

    /// 简体中文脚本包含中文提示。
    func testSimplifiedChineseScriptHasChineseText() {
        let contents = CLIScriptBuilder.scriptContents(language: .simplifiedChinese)
        XCTAssertTrue(contents.contains("未找到 GitOK.app"))
        XCTAssertTrue(contents.contains("路径不存在"))
    }

    /// 繁体中文脚本使用繁体字形。
    func testTraditionalChineseScriptUsesTraditionalCharacters() {
        let contents = CLIScriptBuilder.scriptContents(language: .traditionalChinese)
        XCTAssertTrue(contents.contains("找不到 GitOK.app"))
        XCTAssertTrue(contents.contains("路徑不存在"))
    }

    /// 语言标识解析：繁体变体归入繁体，简体变体归入简体。
    func testLanguageResolutionFromCode() {
        XCTAssertEqual(CLIScriptLanguage.language(for: "zh-Hant"), .traditionalChinese)
        XCTAssertEqual(CLIScriptLanguage.language(for: "zh-TW"), .traditionalChinese)
        XCTAssertEqual(CLIScriptLanguage.language(for: "zh-HK"), .traditionalChinese)
        XCTAssertEqual(CLIScriptLanguage.language(for: "zh-Hans"), .simplifiedChinese)
        XCTAssertEqual(CLIScriptLanguage.language(for: "zh-CN"), .simplifiedChinese)
        XCTAssertEqual(CLIScriptLanguage.language(for: "en"), .english)
        XCTAssertEqual(CLIScriptLanguage.language(for: "en-US"), .english)
    }

    /// 未知语言回落到英文，不产生空脚本。
    func testUnknownLanguageFallsBackToEnglish() {
        XCTAssertEqual(CLIScriptLanguage.language(for: "fr-FR"), .english)
        XCTAssertEqual(CLIScriptLanguage.language(for: nil), CLIScriptLanguage.current)
    }
}
