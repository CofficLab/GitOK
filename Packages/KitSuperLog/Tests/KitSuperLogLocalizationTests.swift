import XCTest
@testable import KitSuperLog

final class KitSuperLogLocalizationTests: XCTestCase {
    func testStringForwardsToLumiLocalization() {
        // Bundle.main 在测试环境中可用；缺失 key 时 LumiLocalization 回退返回 key 本身，
        // 这里仅验证调用路径被覆盖且不抛错。
        let result = KitSuperLogLocalization.string("any.key", bundle: .main, locale: .init(identifier: "en"))
        XCTAssertFalse(result.isEmpty)
    }
}
