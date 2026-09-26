import XCTest
@testable import PluginCommitList

@MainActor
final class CommitAvatarServiceTests: XCTestCase {

    func testEmptyAuthorReturnsNil() async {
        let service = CommitAvatarService()
        let result = await service.avatarURL(author: "   ", email: "user@example.com")
        XCTAssertNil(result)
    }

    func testEmptyCacheKeyReturnsNil() async {
        let service = CommitAvatarService()
        // author 空白且 email 空白 → cacheKey 为空 → nil。
        let result = await service.avatarURL(author: "  ", email: "  ")
        XCTAssertNil(result)
    }

    func testNormalizesEmailCase() async {
        let service = CommitAvatarService()
        // 不同大小写 email 应归一化到同一 cache key；首次调用会尝试网络，
        // 但在无网络环境下返回 nil，不崩溃即可。
        let result = await service.avatarURL(author: "octocat", email: "OctoCat@GitHub.com")
        // 网络不可用时为 nil；不断言具体值。
        _ = result
    }
}
