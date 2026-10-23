import Foundation
import Testing
@testable import ProviderGit

/// 观察者回调是 `@Sendable`，需要跨线程安全地记录收到的值。
private final class EventBox<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: Value

    init(_ value: Value) {
        storage = value
    }

    var value: Value {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }

    func append(_ element: Value.Element) where Value: RangeReplaceableCollection {
        lock.lock()
        storage.append(element)
        lock.unlock()
    }
}

private final class Counter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    var value: Int {
        lock.lock()
        defer { lock.unlock() }
        return count
    }

    func increment() {
        lock.lock()
        count += 1
        lock.unlock()
    }
}

@Suite("WorktreeContentOwnership")
@MainActor
struct WorktreeContentOwnershipTests {
    @Test("Owner stays pending until a snapshot is published")
    func ownerIsPendingBeforeFirstPublish() {
        let ownership = WorktreeContentOwnership()
        let repository = URL(fileURLWithPath: "/tmp/worktree-ownership-pending")

        #expect(ownership.owner(for: repository) == .pending)
    }

    @Test("Publishing an owner notifies observers with the repository")
    func publishNotifiesObservers() {
        let ownership = WorktreeContentOwnership()
        let repository = URL(fileURLWithPath: "/tmp/worktree-ownership-publish")
        let received = EventBox<[(URL, WorktreeContentOwner)]>([])

        let handle = ownership.addObserver { url, owner in
            received.append((url, owner))
        }
        ownership.publish(owner: .changes, for: repository)
        ownership.publish(owner: .clean, for: repository)
        handle.cancel()

        #expect(received.value.count == 2)
        #expect(received.value.first?.0 == repository)
        #expect(received.value.first?.1 == .changes)
        #expect(received.value.last?.1 == .clean)
    }

    @Test("Publishing the same owner twice notifies observers only once")
    func repeatedPublishIsCoalesced() {
        let ownership = WorktreeContentOwnership()
        let repository = URL(fileURLWithPath: "/tmp/worktree-ownership-coalesce")
        let counter = Counter()

        let handle = ownership.addObserver { _, _ in counter.increment() }
        ownership.publish(owner: .clean, for: repository)
        ownership.publish(owner: .clean, for: repository)
        handle.cancel()

        #expect(counter.value == 1)
    }

    @Test("Owner is derived from the snapshot entry count")
    func ownerResolvesFromEntryCount() {
        #expect(WorktreeContentOwner.resolve(entriesCount: 0) == .clean)
        #expect(WorktreeContentOwner.resolve(entriesCount: 2) == .changes)
    }

    @Test("Cancelling an observer stops further notifications")
    func cancelledObserverStopsReceiving() {
        let ownership = WorktreeContentOwnership()
        let repository = URL(fileURLWithPath: "/tmp/worktree-ownership-cancel")
        let counter = Counter()

        let handle = ownership.addObserver { _, _ in counter.increment() }
        ownership.publish(owner: .changes, for: repository)
        handle.cancel()
        ownership.publish(owner: .clean, for: repository)

        #expect(counter.value == 1)
        #expect(ownership.owner(for: repository) == .clean)
    }
}
