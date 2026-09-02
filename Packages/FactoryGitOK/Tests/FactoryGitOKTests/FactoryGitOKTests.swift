import XCTest
@testable import FactoryGitOK

final class FactoryGitOKTests: XCTestCase {
    func testFactorySymbolsExist() {
        // 验证思路的最小占位测试：FactoryGitOK 入口可引用。
        _ = FactoryGitOK.self
    }
}
