import Combine
import Foundation
import XCTest
@testable import ProviderConversation

/// 只实现协议必需成员的轻量 `ConversationManaging`：
/// 用于覆盖 `ConversationManaging` 协议扩展里的默认实现。
@MainActor
private final class MinimalConversationManager: ConversationManaging, ObservableObject {
    var conversations: [ConversationSummary] = []
    var selectedConversationID: UUID?
    var currentTitle: String = "No conversation"
    var dataDirectory: URL = URL(fileURLWithPath: NSTemporaryDirectory())

    var globalVerbosity: ResponseVerbosity = .defaultVerbosity
    var globalReasoningEffort: ReasoningEffort? = .defaultEffort
    var globalAutomationLevel: AutomationLevel = .build
    var globalLanguage: ConversationLanguage = .chinese

    private var perConversationVerbosity: [UUID: ResponseVerbosity] = [:]
    private var perConversationReasoning: [UUID: ReasoningEffort] = [:]
    private var perConversationAutomation: [UUID: AutomationLevel] = [:]
    private var perConversationLanguage: [UUID: ConversationLanguage] = [:]
    private var providerIDs: [UUID: String] = [:]
    private var modelNames: [UUID: String] = [:]
    private var titles: [UUID: String] = [:]

    func createConversation(title: String?, projectPath: String?, providerID: String?, modelName: String?) throws -> UUID {
        try createConversation(
            title: title,
            projectPath: projectPath,
            providerID: providerID,
            modelName: modelName,
            parentConversationID: nil
        )
    }

    func createConversation(
        title: String?,
        projectPath: String?,
        providerID: String?,
        modelName: String?,
        parentConversationID: UUID?
    ) throws -> UUID {
        let id = UUID()
        conversations.append(
            ConversationSummary(
                id: id,
                title: title,
                projectPath: projectPath,
                parentConversationID: parentConversationID
            )
        )
        titles[id] = title
        providerIDs[id] = providerID
        modelNames[id] = modelName
        return id
    }

    func selectConversation(id: UUID) {
        selectedConversationID = id
        currentTitle = titles[id] ?? "No conversation"
    }

    func deselectConversation() {
        selectedConversationID = nil
        currentTitle = "No conversation"
    }

    func deleteConversation(id: UUID) {
        conversations.removeAll { $0.id == id }
    }

    func updateConversationTitle(_ title: String, for conversationID: UUID) -> Bool {
        titles[conversationID] = title
        return true
    }

    func markConversationActive(id: UUID, messageDate: Date) {}

    func isSending(for conversationID: UUID?) -> Bool { false }

    func providerID(for conversationID: UUID?) -> String? {
        guard let conversationID else { return nil }
        return providerIDs[conversationID]
    }

    func modelName(for conversationID: UUID?) -> String? {
        guard let conversationID else { return nil }
        return modelNames[conversationID]
    }

    func selectProvider(id: String, model: String?, for conversationID: UUID?) {
        guard let conversationID else { return }
        providerIDs[conversationID] = id
        modelNames[conversationID] = model
    }

    func setGlobalVerbosity(_ verbosity: ResponseVerbosity) { globalVerbosity = verbosity }

    func setVerbosity(_ verbosity: ResponseVerbosity, for conversationID: UUID?) {
        guard let conversationID else {
            setGlobalVerbosity(verbosity)
            return
        }
        perConversationVerbosity[conversationID] = verbosity
    }

    func verbosity(for conversationID: UUID?) -> ResponseVerbosity {
        guard let conversationID else { return globalVerbosity }
        return perConversationVerbosity[conversationID] ?? globalVerbosity
    }

    func setGlobalReasoningEffort(_ reasoningEffort: ReasoningEffort?) { globalReasoningEffort = reasoningEffort }

    func reasoningEffort(for conversationID: UUID?) -> ReasoningEffort {
        guard let conversationID else { return globalReasoningEffort ?? .defaultEffort }
        return perConversationReasoning[conversationID] ?? globalReasoningEffort ?? .defaultEffort
    }

    func reasoningEffortOptional(for conversationID: UUID?) -> ReasoningEffort? {
        guard let conversationID else { return globalReasoningEffort }
        return perConversationReasoning[conversationID] ?? globalReasoningEffort
    }

    func setReasoningEffort(_ reasoningEffort: ReasoningEffort, for conversationID: UUID?) {
        guard let conversationID else {
            setGlobalReasoningEffort(reasoningEffort)
            return
        }
        perConversationReasoning[conversationID] = reasoningEffort
    }

    func clearReasoningEffort(for conversationID: UUID?) {
        guard let conversationID else {
            setGlobalReasoningEffort(nil)
            return
        }
        perConversationReasoning[conversationID] = nil
    }

    func setGlobalAutomationLevel(_ automationLevel: AutomationLevel) { globalAutomationLevel = automationLevel }

    func automationLevel(for conversationID: UUID?) -> AutomationLevel {
        guard let conversationID else { return globalAutomationLevel }
        return perConversationAutomation[conversationID] ?? globalAutomationLevel
    }

    func setAutomationLevel(_ automationLevel: AutomationLevel, for conversationID: UUID?) {
        guard let conversationID else {
            setGlobalAutomationLevel(automationLevel)
            return
        }
        perConversationAutomation[conversationID] = automationLevel
    }

    func setGlobalLanguage(_ language: ConversationLanguage) { globalLanguage = language }

    func language(for conversationID: UUID?) -> ConversationLanguage {
        guard let conversationID else { return globalLanguage }
        return perConversationLanguage[conversationID] ?? globalLanguage
    }

    func setLanguage(_ language: ConversationLanguage, for conversationID: UUID?) {
        guard let conversationID else {
            setGlobalLanguage(language)
            return
        }
        perConversationLanguage[conversationID] = language
    }

    @discardableResult
    func addSelectedConversationObserver(
        _ callback: @escaping (UUID?) -> Void
    ) -> any SelectedConversationObserverHandle {
        NoopSelectedConversationObserverHandle()
    }
}

/// `ConversationManaging` 协议扩展默认实现的覆盖。
@MainActor
final class ConversationManagingDefaultsTests: XCTestCase {

    func testDefaultSortedConversationsMirrorsConversations() throws {
        let manager = MinimalConversationManager()
        _ = try manager.createConversation(title: "A", projectPath: nil, providerID: nil, modelName: nil)

        XCTAssertEqual(manager.sortedConversations.count, manager.conversations.count)
    }

    func testDefaultIsLoadingConversationsIsFalse() {
        let manager = MinimalConversationManager()

        XCTAssertFalse(manager.isLoadingConversations)
    }

    func testDefaultFetchConversationPageOverloads() async throws {
        let manager = MinimalConversationManager()
        _ = try manager.createConversation(title: "A", projectPath: nil, providerID: nil, modelName: nil)
        _ = try manager.createConversation(title: "B", projectPath: nil, providerID: nil, modelName: nil)

        let page = await manager.fetchConversationPage(limit: 1, beforeUpdatedAt: nil, beforeID: nil)
        XCTAssertEqual(page.count, 1)

        let withChildren = await manager.fetchConversationPage(
            limit: 10,
            beforeUpdatedAt: nil,
            beforeID: nil,
            includingChildConversations: true
        )
        XCTAssertEqual(withChildren.count, 2)

        let withProject = await manager.fetchConversationPage(
            limit: 10,
            beforeUpdatedAt: nil,
            beforeID: nil,
            includingChildConversations: false,
            projectPath: "/p1"
        )
        XCTAssertEqual(withProject.count, 2)
    }

    func testDefaultFetchConversationAndCounts() async throws {
        let manager = MinimalConversationManager()
        let id = try manager.createConversation(
            title: "A",
            projectPath: "/p1",
            providerID: nil,
            modelName: nil
        )
        _ = try manager.createConversation(title: "B", projectPath: "/p2", providerID: nil, modelName: nil)

        let fetched = await manager.fetchConversation(id: id)
        XCTAssertEqual(fetched?.title, "A")

        let missing = await manager.fetchConversation(id: UUID())
        XCTAssertNil(missing)

        let count = await manager.conversationCount(projectPath: nil)
        XCTAssertEqual(count, 2)

        let countWithChildren = await manager.conversationCount(
            projectPath: nil,
            includingChildConversations: true
        )
        XCTAssertEqual(countWithChildren, 2)

        let projectCount = await manager.conversationProjectCount()
        XCTAssertEqual(projectCount, 2)
    }

    func testDefaultObserverRegistrationReturnsNoopHandles() {
        let manager = MinimalConversationManager()

        let conversationToken = manager.addConversationObserver { _ in }
        let selectedToken = manager.addSelectedConversationObserver { _ in }

        XCTAssertTrue(conversationToken is NoopConversationObserverHandle)
        XCTAssertTrue(selectedToken is NoopSelectedConversationObserverHandle)

        conversationToken.cancel()
        selectedToken.cancel()

        // transferObservers 的默认实现是空操作。
        let replacement = MinimalConversationManager()
        manager.transferObservers(to: replacement)
    }
}
