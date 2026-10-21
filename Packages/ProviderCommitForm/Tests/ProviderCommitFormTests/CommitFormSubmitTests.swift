import Foundation
import KitGit
import ProviderGit
import Testing
@testable import ProviderCommitForm

/// `DefaultCommitFormProvider.submit` 的执行链路覆盖。
@Suite("DefaultCommitFormProvider 提交链路")
@MainActor
struct CommitFormSubmitTests {

    private let repository = URL(fileURLWithPath: "/tmp/commit-form-repository")

    private func makeProvider(git: CommitFormTestDoubles.Git?) -> DefaultCommitFormProvider {
        DefaultCommitFormProvider(subject: "Subject", category: .Chore, style: .emoji, git: git)
    }

    @Test("只提交时不推送")
    func commitOnlyDoesNotPush() async throws {
        let git = CommitFormTestDoubles.Git()
        let provider = makeProvider(git: git)
        var events: [CommitFormEvent] = []
        let handle = provider.addObserver { events.append($0) }
        defer { handle.cancel() }

        try await provider.submit(commitOnly: true, in: repository)

        #expect(git.addAllCount == 1)
        #expect(git.commitMessages.count == 1)
        #expect(git.pushCount == 0)
        #expect(git.synchronizeCount == 0)
        #expect(provider.isSubmitting == false)
        #expect(provider.lastErrorMessage == nil)
        #expect(events.contains { if case .committed = $0 { return true } else { return false } })
    }

    @Test("提交并推送且没有 upstream 时走普通 push")
    func commitAndPushWithoutUpstreamUsesPush() async throws {
        let git = CommitFormTestDoubles.Git()
        git.trackingStatus = GitRefReader.RemoteTrackingStatus(ahead: 0, behind: 0, hasUpstream: false)
        let provider = makeProvider(git: git)

        try await provider.submit(commitOnly: false, in: repository)

        #expect(git.pushCount == 1)
        #expect(git.synchronizeCount == 0)
    }

    @Test("提交并推送且已有 upstream 时走 synchronize")
    func commitAndPushWithUpstreamUsesSynchronize() async throws {
        let git = CommitFormTestDoubles.Git()
        git.trackingStatus = GitRefReader.RemoteTrackingStatus(ahead: 1, behind: 0, hasUpstream: true)
        let provider = makeProvider(git: git)

        try await provider.submit(commitOnly: false, in: repository)

        #expect(git.synchronizeCount == 1)
        #expect(git.pushCount == 0)
    }

    @Test("提交信息包含类别前缀与共同作者")
    func submittedMessageContainsPrefixAndCoAuthors() async throws {
        let git = CommitFormTestDoubles.Git()
        let provider = DefaultCommitFormProvider(
            subject: "Improve the thing",
            category: .Feature,
            style: .emoji,
            coAuthors: [CoAuthor(name: "Jane", email: "jane@t.com")],
            git: git
        )

        try await provider.submit(commitOnly: true, in: repository)

        let message = git.commitMessages.first ?? ""
        #expect(message.hasPrefix("\(CommitCategory.Feature.text)Improve the thing"))
        #expect(message.contains("Co-authored-by: Jane <jane@t.com>"))
    }

    @Test("没有 Git 后端时提交失败并广播 submitFailed")
    func submitWithoutGitBackendFails() async throws {
        let provider = makeProvider(git: nil)
        var events: [CommitFormEvent] = []
        let handle = provider.addObserver { events.append($0) }
        defer { handle.cancel() }

        await #expect(throws: (any Error).self) {
            try await provider.submit(commitOnly: true, in: repository)
        }

        #expect(provider.isSubmitting == false)
        #expect(provider.lastErrorMessage != nil)
        #expect(events.contains { if case .submitFailed = $0 { return true } else { return false } })
    }

    @Test("提交成功后 subject 重置为默认信息")
    func subjectResetsAfterSuccessfulSubmit() async throws {
        let git = CommitFormTestDoubles.Git()
        let provider = makeProvider(git: git)

        try await provider.submit(commitOnly: true, in: repository)

        #expect(provider.subject == CommitCategory.Chore.defaultMessage)
    }

    @Test("活动上报器在提交前后收到阶段文案")
    func activityReporterReceivesStages() async throws {
        let git = CommitFormTestDoubles.Git()
        let provider = makeProvider(git: git)
        var stages: [String?] = []
        provider.activityReporter = { stage in stages.append(stage) }

        try await provider.submit(commitOnly: true, in: repository)

        #expect(stages.count == 2)
        let first = stages.first ?? nil
        #expect(first?.isEmpty == false)
        let last = stages.last ?? nil
        #expect(last == nil)
    }
}

/// 提交表单的状态与观察者行为覆盖。
@Suite("DefaultCommitFormProvider 状态与观察者")
@MainActor
struct CommitFormStateTests {

    @Test("相同值不会重复广播状态变化")
    func identicalValuesDoNotNotify() {
        let provider = DefaultCommitFormProvider(subject: "S", category: .Chore, style: .emoji)
        var events: [CommitFormEvent] = []
        let handle = provider.addObserver { events.append($0) }
        defer { handle.cancel() }

        provider.setSubject("S")
        provider.setCategory(.Chore)
        provider.setStyle(.emoji)
        provider.setCoAuthors([])

        #expect(events.isEmpty)
    }

    @Test("setCoAuthors 变化会广播状态变化")
    func coAuthorChangeNotifies() {
        let provider = DefaultCommitFormProvider()
        var events: [CommitFormEvent] = []
        let handle = provider.addObserver { events.append($0) }
        defer { handle.cancel() }

        provider.setCoAuthors([CoAuthor(name: "Jane", email: "jane@t.com")])

        #expect(events.count == 1)
        #expect(provider.coAuthors.count == 1)
    }

    @Test("观察者取消后不再收到事件")
    func cancelledObserverStopsReceiving() {
        let provider = DefaultCommitFormProvider()
        var events: [CommitFormEvent] = []
        let handle = provider.addObserver { events.append($0) }

        provider.setSubject("first")
        #expect(events.count == 1)

        handle.cancel()
        provider.setSubject("second")

        #expect(events.count == 1)
    }

    @Test("loadStyle(nil) 回退全局默认风格")
    func loadStyleNilFallsBackToGlobal() {
        let provider = DefaultCommitFormProvider()
        provider.setStyle(.plain)

        provider.loadStyle(for: nil)

        #expect(provider.style == CommitStyleStore.current)
    }
}
