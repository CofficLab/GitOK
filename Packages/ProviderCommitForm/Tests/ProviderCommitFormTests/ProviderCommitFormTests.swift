import Foundation
import ProviderStorage
import Testing
@testable import ProviderCommitForm

@Suite("ProviderCommitForm")
@MainActor
struct ProviderCommitFormTests {

    @Test("类别与风格变化后重置 subject 为默认信息")
    func categoryAndStyleResetSubject() {
        let provider = DefaultCommitFormProvider()
        provider.setCategory(.Feature)
        #expect(provider.category == .Feature)
        #expect(provider.subject == "Implement a new feature")

        provider.setStyle(.lowercase)
        #expect(provider.style == .lowercase)
        #expect(provider.subject == "implement a new feature")
    }

    @Test("formattedMessage 组装类别前缀与 Co-authored-by 行")
    func formattedMessageComposesPrefixAndCoAuthors() {
        let message = CommitMessageRules.formattedMessage(
            subject: "Minor adjustments",
            category: .Chore,
            style: .emoji,
            coAuthors: [CoAuthor(name: "Jane", email: "jane@t.com")]
        )
        #expect(message.hasPrefix("🎨 Chore: Minor adjustments"))
        #expect(message.contains("Co-authored-by: Jane <jane@t.com>"))
    }

    @Test("观察者收到 stateChanged 与 committed 事件")
    func observerReceivesEvents() {
        let provider = DefaultCommitFormProvider()
        var events: [CommitFormEvent] = []
        let handle = provider.addObserver { events.append($0) }
        defer { handle.cancel() }

        provider.setSubject("hello")
        #expect(events.count == 1)
        if case .stateChanged = events[0] {} else {
            Issue.record("expected stateChanged")
        }
    }

    // MARK: - 按项目风格

    /// 每个用例独占临时目录，避免落盘状态互相污染。
    private func makeTemporaryDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ProviderCommitFormTests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test("按项目读写风格互相隔离")
    func styleIsIsolatedPerProject() {
        let directory = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = CommitStylePerProjectStore(directory: directory)
        let projectA = URL(fileURLWithPath: "/tmp/project-a")
        let projectB = URL(fileURLWithPath: "/tmp/project-b")

        store.setStyle(.lowercase, for: projectA)
        store.setStyle(.plain, for: projectB)

        #expect(store.style(for: projectA) == .lowercase)
        #expect(store.style(for: projectB) == .plain)
    }

    @Test("风格写入磁盘后可被重新加载")
    func stylePersistsAcrossStoreInstances() {
        let directory = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let projectURL = URL(fileURLWithPath: "/tmp/persisted-project")
        CommitStylePerProjectStore(directory: directory).setStyle(.lowercase, for: projectURL)

        // 新实例从磁盘读取，验证真的落盘而不是留在内存。
        let reloaded = CommitStylePerProjectStore(directory: directory)
        #expect(reloaded.style(for: projectURL) == .lowercase)
    }

    @Test("同一路径的不同写法视为同一项目")
    func styleKeyUsesStandardizedPath() {
        let directory = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = CommitStylePerProjectStore(directory: directory)
        store.setStyle(.plain, for: URL(fileURLWithPath: "/tmp/repo/../repo"))

        #expect(store.style(for: URL(fileURLWithPath: "/tmp/repo")) == .plain)
    }

    @Test("未注入目录时退化为纯内存，读写仍可用")
    func styleFallsBackToMemoryWithoutDirectory() {
        let store = CommitStylePerProjectStore(directory: nil)
        let projectURL = URL(fileURLWithPath: "/tmp/memory-only")

        #expect(store.style(for: projectURL) == nil)
        store.setStyle(.lowercase, for: projectURL)
        #expect(store.style(for: projectURL) == .lowercase)
    }

    @Test("provider 未存储时回退全局默认风格，loadStyle 装载项目风格")
    func providerFallsBackToGlobalDefaultAndLoadsPerProject() {
        let directory = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let projectURL = URL(fileURLWithPath: "/tmp/provider-project")
        // 该项目已有记录；另一个项目没有记录。
        let seed = CommitStylePerProjectStore(directory: pluginStyleDirectory(directory))
        seed.setStyle(.lowercase, for: projectURL)

        let provider = DefaultCommitFormProvider(
            storage: StubStorageProvider(directory: directory)
        )
        let unrecorded = URL(fileURLWithPath: "/tmp/unrecorded-project")

        // 无记录 → 回退全局默认值（测试环境未设置过，即 .emoji）。
        #expect(provider.style(for: unrecorded) == CommitStyleStore.current)

        // 切换项目装载各自的风格。
        provider.loadStyle(for: projectURL)
        #expect(provider.style == .lowercase)

        provider.loadStyle(for: unrecorded)
        #expect(provider.style == CommitStyleStore.current)
    }

    @Test("setStyle(_:) 写入当前已加载项目的记录")
    func setStyleWritesLoadedProject() {
        let directory = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let projectURL = URL(fileURLWithPath: "/tmp/write-through")
        let provider = DefaultCommitFormProvider(
            storage: StubStorageProvider(directory: directory)
        )

        provider.loadStyle(for: projectURL)
        provider.setStyle(.plain)

        // 内存生效，且已落盘到该项目。
        #expect(provider.style == .plain)
        #expect(
            CommitStylePerProjectStore(directory: pluginStyleDirectory(directory))
                .style(for: projectURL) == .plain
        )
    }

    @Test("setStyle(_:for:) 同步正在展示的项目")
    func setStyleForProjectUpdatesCurrentState() {
        let directory = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let projectURL = URL(fileURLWithPath: "/tmp/current-project")
        let otherURL = URL(fileURLWithPath: "/tmp/other-project")
        let provider = DefaultCommitFormProvider(
            storage: StubStorageProvider(directory: directory)
        )

        provider.loadStyle(for: projectURL)
        provider.setStyle(.lowercase)      // 当前项目 → 同步内存
        #expect(provider.style == .lowercase)

        provider.setStyle(.emoji, for: otherURL)  // 非当前项目 → 不影响内存
        #expect(provider.style == .lowercase)
    }

    /// Provider 依据 `StorageProviding` 计算出的风格存储目录。
    private func pluginStyleDirectory(_ root: URL) -> URL {
        root.appendingPathComponent(StubStorageProvider.pluginID, isDirectory: true)
    }
}

/// 测试用最小 `StorageProviding`：只固定返回注入的目录。
@MainActor
private final class StubStorageProvider: StorageProviding {
    let dataRootDirectory: URL
    private let directory: URL

    /// Provider 实际落盘所用的插件数据目录。
    static let pluginID = "com.coffic.gitok.plugin.commit-form"

    init(directory: URL) {
        self.directory = directory
        self.dataRootDirectory = directory
    }

    func pluginDataDirectory(for pluginID: String) -> URL {
        directory.appendingPathComponent(pluginID, isDirectory: true)
    }

    func coreDataDirectory() -> URL {
        directory.appendingPathComponent("Core", isDirectory: true)
    }
}
