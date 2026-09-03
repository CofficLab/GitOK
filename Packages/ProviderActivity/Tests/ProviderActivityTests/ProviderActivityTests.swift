import Foundation
import Testing
@testable import ProviderActivity

@Suite("ProviderActivity")
@MainActor
struct ProviderActivityTests {

    @Test("setActivity / clearActivity 更新状态并广播")
    func activityStateAndEvents() {
        let provider = DefaultActivityProvider()
        var events: [ActivityEvent] = []
        let handle = provider.addObserver { events.append($0) }
        defer { handle.cancel() }

        #expect(provider.currentActivity == nil)
        provider.setActivity("Committing...")
        #expect(provider.currentActivity == "Committing...")
        #expect(events.count == 1)

        provider.clearActivity()
        #expect(provider.currentActivity == nil)
        #expect(events.count == 2)
    }

    @Test("相同值不重复广播")
    func dedup() {
        let provider = DefaultActivityProvider()
        var count = 0
        let handle = provider.addObserver { _ in count += 1 }
        defer { handle.cancel() }

        provider.setActivity("X")
        provider.setActivity("X")
        #expect(count == 1)
    }
}
