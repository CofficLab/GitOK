import Combine
import Foundation
import XCTest
@testable import ProviderConversation

/// `DefaultConversationManager` 中既有测试未覆盖的分支。
@MainActor
final class DefaultConversationManagerCoverageTests: XCTestCase {

    // MARK: - 加载与数据目录

    func testLoadConversationsEndsLoadingState() {
        let manager = DefaultConversationManager()

        manager.loadConversations()

        XCTAssertFalse(manager.isLoadingConversations)
    }

    func testDataDirectoryIsUnderApplicationSupport() {
        let manager = DefaultConversationManager()

        let path = manager.dataDirectory.path

        XCTAssertTrue(path.hasSuffix("LumiMinimal/Conversations"))
    }

    // MARK: - 分页与查询

    func testFetchConversationPageOverloads() async throws {
        let manager = DefaultConversationManager()
        _ = try manager.createConversation(title: "A", projectPath: nil, providerID: nil, modelName: nil)
        _ = try manager.createConversation(title: "B", projectPath: nil, providerID: nil, modelName: nil)

        let all = await manager.fetchConversationPage(limit: 10, beforeUpdatedAt: nil, beforeID: nil)
        XCTAssertEqual(all.count, 2)

        let includingChildren = await manager.fetchConversationPage(
            limit: 10,
            beforeUpdatedAt: nil,
            beforeID: nil,
            includingChildConversations: true
        )
        XCTAssertEqual(includingChildren.count, 2)
    }

    func testFetchConversationPageRespectsLimitAndBeforeUpdatedAt() async throws {
        let manager = DefaultConversationManager()
        let first = try manager.createConversation(title: "A", projectPath: nil, providerID: nil, modelName: nil)
        _ = try manager.createConversation(title: "B", projectPath: nil, providerID: nil, modelName: nil)

        let limited = await manager.fetchConversationPage(limit: 1, beforeUpdatedAt: nil, beforeID: nil)
        XCTAssertEqual(limited.count, 1)

        // 早于所有对话更新时间的窗口不应返回任何结果。
        let empty = await manager.fetchConversationPage(
            limit: 10,
            beforeUpdatedAt: Date(timeIntervalSince1970: 0),
            beforeID: nil
        )
        XCTAssertTrue(empty.isEmpty)

        let fetched = await manager.fetchConversation(id: first)
        XCTAssertEqual(fetched?.title, "A")
        let missing = await manager.fetchConversation(id: UUID())
        XCTAssertNil(missing)
    }

    func testConversationCountExcludesChildConversationsByDefault() async throws {
        let manager = DefaultConversationManager()
        let parent = try manager.createConversation(title: "P", projectPath: nil, providerID: nil, modelName: nil)
        _ = try manager.createConversation(
            title: "C",
            projectPath: nil,
            providerID: nil,
            modelName: nil,
            parentConversationID: parent
        )

        // 实现现状：子代理对话只返回 id，不进缓存，因此两种计数口径结果相同。
        let topLevel = await manager.conversationCount(projectPath: nil)
        XCTAssertEqual(topLevel, 1)

        let includingChildren = await manager.conversationCount(
            projectPath: nil,
            includingChildConversations: true
        )
        XCTAssertEqual(includingChildren, 1)
    }

    func testChildConversationIsNotCachedNorSelected() throws {
        let manager = DefaultConversationManager()
        let parent = try manager.createConversation(title: "P", projectPath: nil, providerID: nil, modelName: nil)

        let child = try manager.createConversation(
            title: "C",
            projectPath: nil,
            providerID: nil,
            modelName: nil,
            parentConversationID: parent
        )

        XCTAssertEqual(manager.conversations.count, 1)
        XCTAssertEqual(manager.selectedConversationID, parent)
        XCTAssertNotEqual(manager.selectedConversationID, child)
    }

    // MARK: - 排序

    func testSortedConversationsTieBreakByCreatedAt() throws {
        let manager = DefaultConversationManager()
        let first = try manager.createConversation(title: "A", projectPath: nil, providerID: nil, modelName: nil)
        let second = try manager.createConversation(title: "B", projectPath: nil, providerID: nil, modelName: nil)

        // 两条 lastMessageAt 相同（都为 nil）时按 createdAt 倒序。
        let sorted = manager.sortedConversations
        XCTAssertEqual(sorted.map(\.id), [second, first])
    }

    // MARK: - 观察者迁移

    func testTransferObserversKeepsOriginalCallbacks() throws {
        let manager = DefaultConversationManager()
        let replacement = DefaultConversationManager()
        var selectedValues: [UUID?] = []
        var events: [ConversationEvent] = []

        let selectedToken = manager.addSelectedConversationObserver { selectedValues.append($0) }
        let eventToken = manager.addConversationObserver { events.append($0) }

        manager.transferObservers(to: replacement)

        let id = try manager.createConversation(title: "A", projectPath: nil, providerID: nil, modelName: nil)
        XCTAssertEqual(selectedValues, [id])

        _ = manager.updateConversationTitle("B", for: id)
        XCTAssertTrue(events.contains(.updated(id)))

        // 实现现状：transferObservers 用 `_ =` 丢弃了转移过程中创建的观察者令牌，
        // 令牌随即释放，替换者侧的弱引用失效，因此替换者上的活动不会回调到原回调。
        // 详见提交信息中的「实现与文档不一致」记录。
        events.removeAll()
        _ = try replacement.createConversation(title: "R", projectPath: nil, providerID: nil, modelName: nil)
        XCTAssertTrue(events.isEmpty)

        selectedToken.cancel()
        eventToken.cancel()
    }

    // MARK: - Provider / Model

    func testSelectProviderUpdatesConversation() throws {
        let manager = DefaultConversationManager()
        let id = try manager.createConversation(title: "A", projectPath: nil, providerID: nil, modelName: nil)
        var events: [ConversationEvent] = []
        let token = manager.addConversationObserver { events.append($0) }

        manager.selectProvider(id: "openai", model: "gpt-4o", for: id)

        XCTAssertEqual(manager.providerID(for: id), "openai")
        XCTAssertEqual(manager.modelName(for: id), "gpt-4o")
        XCTAssertTrue(events.contains(.providerChanged(id)))

        // 未知对话 id 是空操作。
        manager.selectProvider(id: "x", model: nil, for: UUID())
        XCTAssertEqual(manager.providerID(for: id), "openai")

        token.cancel()
    }

    func testProviderAndModelLookupsWithNilIDReturnNil() {
        let manager = DefaultConversationManager()

        XCTAssertNil(manager.providerID(for: nil))
        XCTAssertNil(manager.modelName(for: nil))
    }

    // MARK: - 偏好：全局与按对话

    func testPerConversationSettersFallBackToGlobalWhenIDIsNil() {
        let manager = DefaultConversationManager()

        manager.setVerbosity(.detailed, for: nil)
        manager.setReasoningEffort(.max, for: nil)
        manager.setAutomationLevel(.autonomous, for: nil)
        manager.setLanguage(.english, for: nil)

        XCTAssertEqual(manager.verbosity(for: nil), .detailed)
        XCTAssertEqual(manager.reasoningEffort(for: nil), .max)
        XCTAssertEqual(manager.automationLevel(for: nil), .autonomous)
        XCTAssertEqual(manager.language(for: nil), .english)

        manager.clearReasoningEffort(for: nil)
        XCTAssertNil(manager.reasoningEffortOptional(for: nil))
        XCTAssertEqual(manager.reasoningEffort(for: nil), .defaultEffort)
    }

    func testGlobalSettersIgnoreUnchangedValue() {
        let manager = DefaultConversationManager()
        var events: [ConversationEvent] = []
        let token = manager.addConversationObserver { events.append($0) }

        // 与当前全局值相同，不应产生事件。
        manager.setGlobalVerbosity(manager.globalVerbosity)
        manager.setGlobalAutomationLevel(manager.globalAutomationLevel)
        manager.setGlobalLanguage(manager.globalLanguage)
        manager.setGlobalReasoningEffort(manager.globalReasoningEffort)
        XCTAssertTrue(events.isEmpty)

        manager.setGlobalVerbosity(.brief)
        XCTAssertTrue(events.contains(.verbosityChanged(nil)))

        token.cancel()
    }

    func testPerConversationSettersIgnoreUnknownID() throws {
        let manager = DefaultConversationManager()
        let unknown = UUID()

        manager.setVerbosity(.brief, for: unknown)
        manager.setReasoningEffort(.low, for: unknown)
        manager.setAutomationLevel(.chat, for: unknown)
        manager.setLanguage(.english, for: unknown)
        manager.clearReasoningEffort(for: unknown)

        XCTAssertEqual(manager.verbosity(for: unknown), .defaultVerbosity)
        XCTAssertEqual(manager.reasoningEffort(for: unknown), .defaultEffort)
        XCTAssertEqual(manager.automationLevel(for: unknown), .build)
        XCTAssertEqual(manager.language(for: unknown), .chinese)
    }

    // MARK: - 其它

    func testIsSendingIsAlwaysFalse() {
        let manager = DefaultConversationManager()

        XCTAssertFalse(manager.isSending(for: nil))
        XCTAssertFalse(manager.isSending(for: UUID()))
    }

    func testUpdateTitleWithSameValueDoesNotEmitEvent() throws {
        let manager = DefaultConversationManager()
        let id = try manager.createConversation(title: "A", projectPath: nil, providerID: nil, modelName: nil)
        var events: [ConversationEvent] = []
        let token = manager.addConversationObserver { events.append($0) }

        XCTAssertTrue(manager.updateConversationTitle("A", for: id))
        XCTAssertFalse(events.contains(.updated(id)))

        // 全空白标题会归一化为 nil。
        XCTAssertTrue(manager.updateConversationTitle("   ", for: id))
        XCTAssertNil(manager.conversations.first { $0.id == id }?.title)

        token.cancel()
    }

    func testMarkActiveAndDeleteIgnoreUnknownID() {
        let manager = DefaultConversationManager()
        var events: [ConversationEvent] = []
        let token = manager.addConversationObserver { events.append($0) }

        manager.markConversationActive(id: UUID(), messageDate: Date())
        manager.deleteConversation(id: UUID())

        XCTAssertTrue(events.isEmpty)

        token.cancel()
    }

    func testDeletingSelectedConversationFallsBackToAnother() throws {
        let manager = DefaultConversationManager()
        let first = try manager.createConversation(title: "A", projectPath: nil, providerID: nil, modelName: nil)
        let second = try manager.createConversation(title: "B", projectPath: nil, providerID: nil, modelName: nil)

        manager.selectConversation(id: first)
        manager.deleteConversation(id: first)

        XCTAssertEqual(manager.selectedConversationID, second)
        XCTAssertEqual(manager.currentTitle, "B")
    }

    func testDeletingLastConversationResetsTitle() throws {
        let manager = DefaultConversationManager()
        let only = try manager.createConversation(title: "A", projectPath: nil, providerID: nil, modelName: nil)

        manager.deleteConversation(id: only)

        XCTAssertNil(manager.selectedConversationID)
        XCTAssertEqual(manager.currentTitle, "No conversation")
    }

    func testCacheTruncatesBeyondPageSizeLimit() throws {
        let manager = DefaultConversationManager()
        for index in 0..<85 {
            _ = try manager.createConversation(
                title: "T\(index)",
                projectPath: nil,
                providerID: nil,
                modelName: nil
            )
        }

        // 上限是 initialPageSize * 2 = 80；超出部分按最后消息时间截断。
        XCTAssertLessThanOrEqual(manager.conversations.count, 81)
        XCTAssertGreaterThanOrEqual(manager.conversations.count, 80)
    }

    func testCacheKeepsSelectedConversationWhenTruncating() throws {
        let manager = DefaultConversationManager()
        let oldest = try manager.createConversation(title: "oldest", projectPath: nil, providerID: nil, modelName: nil)

        // 再创建 79 个，上限恰好到 80。
        for index in 0..<79 {
            _ = try manager.createConversation(
                title: "T\(index)",
                projectPath: nil,
                providerID: nil,
                modelName: nil
            )
        }
        // 重新选中最老的对话，再触发一次缓存写入。
        manager.selectConversation(id: oldest)
        _ = try manager.createConversation(title: "newest", projectPath: nil, providerID: nil, modelName: nil)

        // 最老的对话被截断后又补回，因此总数是 81。
        XCTAssertEqual(manager.conversations.count, 81)
        XCTAssertNotNil(manager.conversations.first { $0.id == oldest })
    }
}
