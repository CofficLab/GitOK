@testable import KitGitOKUpdate
import Foundation
import Testing

@Suite("KitGitOKUpdate")
struct KitGitOKUpdateTests {
    @Test("uses GitOK feed hosts")
    func feedHosts() {
        let arm64Primary = UpdateFeedURLProvider.primary(forArchitecture: "arm64")
        let x86Primary = UpdateFeedURLProvider.primary(forArchitecture: "x86_64")
        #expect(arm64Primary.host == "api.kuaiyizhi.cn")
        #expect(arm64Primary.path == "/gitok/appcast.xml")
        #expect(URLComponents(url: arm64Primary, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "arch" })?.value == "arm64")
        #expect(URLComponents(url: x86Primary, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "arch" })?.value == "x86_64")
        #expect(UpdateFeedURLProvider.fallback(forArchitecture: "x86_64").host == "github.com")
        #expect(UpdateFeedURLProvider.fallback(forArchitecture: "arm64").lastPathComponent == "appcast-arm64.xml")
    }

    @Test("retains update notification names")
    func notificationNames() {
        #expect(Notification.Name.checkForUpdates.rawValue == "checkForUpdates")
        #expect(Notification.Name.appUpdateReadyToInstall.rawValue == "appUpdateReadyToInstall")
        #expect(Notification.Name.installPreparedAppUpdate.rawValue == "installPreparedAppUpdate")
    }

    @Test("falls back when primary feed is unreachable")
    func feedFallback() async {
        let primary = URL(string: "https://primary.example/appcast.xml")!
        let fallback = URL(string: "https://fallback.example/appcast.xml")!
        let detector = FeedURLDetector(
            initialURL: primary,
            reachabilityChecker: MockReachability(isReachable: false),
            fallbackURL: fallback
        )

        await detector.detectIfNeeded()

        #expect(await detector.resolvedFeedURL == fallback)
    }

    @Test("keeps primary feed when reachable")
    func feedKeepsPrimary() async {
        let primary = URL(string: "https://primary.example/appcast.xml")!
        let fallback = URL(string: "https://fallback.example/appcast.xml")!
        let detector = FeedURLDetector(
            initialURL: primary,
            reachabilityChecker: MockReachability(isReachable: true),
            fallbackURL: fallback
        )

        await detector.detectIfNeeded()

        #expect(await detector.resolvedFeedURL == primary)
    }

    @Test("caches detection within cache window")
    func feedDetectionCaches() async {
        let primary = URL(string: "https://primary.example/appcast.xml")!
        let fallback = URL(string: "https://fallback.example/appcast.xml")!
        let clock = _MutableClock(start: Date(timeIntervalSince1970: 1_000_000))
        let checker = CountingReachability(isReachable: false)
        let detector = FeedURLDetector(
            initialURL: primary,
            reachabilityChecker: checker,
            fallbackURL: fallback,
            cacheWindow: 1800,
            clock: { clock.now() }
        )

        await detector.detectIfNeeded()
        #expect(checker.callCount == 1)
        #expect(await detector.resolvedFeedURL == fallback)

        // Advance clock by less than the cache window; should not re-detect.
        clock.advance(by: 600)
        await detector.detectIfNeeded()
        #expect(checker.callCount == 1)

        // Advance past the cache window; should re-detect.
        clock.advance(by: 1800)
        await detector.detectIfNeeded()
        #expect(checker.callCount == 2)
    }

    @Test("forceRedetect bypasses cache")
    func forceRedetectBypassesCache() async {
        let primary = URL(string: "https://primary.example/appcast.xml")!
        let fallback = URL(string: "https://fallback.example/appcast.xml")!
        let clock = _MutableClock(start: Date(timeIntervalSince1970: 1_000_000))
        let checker = CountingReachability(isReachable: false)
        let detector = FeedURLDetector(
            initialURL: primary,
            reachabilityChecker: checker,
            fallbackURL: fallback,
            cacheWindow: 1800,
            clock: { clock.now() }
        )

        await detector.detectIfNeeded()
        #expect(checker.callCount == 1)

        // Even within the cache window, forceRedetect re-probes.
        clock.advance(by: 10)
        await detector.forceRedetect()
        #expect(checker.callCount == 2)
    }

    @Test("tracks lifecycle transitions")
    func lifecycleTransitions() async {
        let stateMachine = UpdateServiceStateMachine()

        await stateMachine.beginChecking()
        #expect(await stateMachine.state == .checking)
        await stateMachine.beginDownloading()
        #expect(await stateMachine.state == .downloading)
        await stateMachine.markReadyToInstall(version: "4.0.17")
        #expect(await stateMachine.state == .readyToInstall)
        #expect(await stateMachine.latestVersion == "4.0.17")
        await stateMachine.beginInstalling()
        #expect(await stateMachine.state == .installing)
    }

    @Test("markError sets error state")
    func markError() async {
        let stateMachine = UpdateServiceStateMachine()
        await stateMachine.beginChecking()
        await stateMachine.markError()
        #expect(await stateMachine.state == .error)
    }

    @Test("finishCheckingIfNeeded only leaves checking state")
    func finishCheckingIfNeeded() async {
        let stateMachine = UpdateServiceStateMachine()

        // Already idle: stays idle.
        await stateMachine.finishCheckingIfNeeded()
        #expect(await stateMachine.state == .idle)

        // In checking: returns to idle.
        await stateMachine.beginChecking()
        await stateMachine.finishCheckingIfNeeded()
        #expect(await stateMachine.state == .idle)

        // In downloading: does not reset.
        await stateMachine.beginDownloading()
        await stateMachine.finishCheckingIfNeeded()
        #expect(await stateMachine.state == .downloading)
    }

    @Test("reset clears state and version")
    func resetStateMachine() async {
        let stateMachine = UpdateServiceStateMachine()
        await stateMachine.markReadyToInstall(version: "5.0.0")
        await stateMachine.reset()
        #expect(await stateMachine.state == .idle)
        #expect(await stateMachine.latestVersion == nil)
    }

    @Test("posts check-for-updates notification")
    func postsCheckForUpdates() async {
        let didPost = expectationBool()
        let token = NotificationCenter.default.addObserver(
            forName: .checkForUpdates,
            object: nil,
            queue: .main
        ) { _ in didPost.set(true) }

        NotificationCenter.postCheckForUpdates()

        await waitUntil(didPost)
        NotificationCenter.default.removeObserver(token)
    }

    @Test("posts ready-to-install notification with version")
    func postsReadyToInstall() async {
        let didPost = expectationBool()
        let versionBox = _StringBox()
        let token = NotificationCenter.default.addObserver(
            forName: .appUpdateReadyToInstall,
            object: nil,
            queue: .main
        ) { note in
            versionBox.value = note.userInfo?["version"] as? String
            didPost.set(true)
        }

        NotificationCenter.postAppUpdateReadyToInstall(version: "4.0.17")

        await waitUntil(didPost)
        #expect(versionBox.value == "4.0.17")
        NotificationCenter.default.removeObserver(token)
    }

    @Test("posts install-prepared notification")
    func postsInstallPrepared() async {
        let didPost = expectationBool()
        let token = NotificationCenter.default.addObserver(
            forName: .installPreparedAppUpdate,
            object: nil,
            queue: .main
        ) { _ in didPost.set(true) }

        NotificationCenter.postInstallPreparedAppUpdate()

        await waitUntil(didPost)
        NotificationCenter.default.removeObserver(token)
    }

    @Test("runtime environment defaults to false in debug")
    func runtimeEnvironmentDebugDefault() {
        // In DEBUG builds (tests run in debug), updates are disabled unless
        // Info.plist overrides. Bundle.main in tests has no override, so the
        // DEBUG fallback should be false.
        #expect(AppUpdateRuntimeEnvironment.allowsAppUpdates == false)
    }

    @Test("observer dispatches check and install callbacks")
    @MainActor
    func observerDispatchesCallbacks() async {
        var checkCount = 0
        var installCount = 0
        let observer = UpdateRequestObserver(
            onCheckForUpdates: { checkCount += 1 },
            onInstallPreparedUpdate: { installCount += 1 }
        )

        NotificationCenter.postCheckForUpdates()
        NotificationCenter.postInstallPreparedAppUpdate()

        // Give the main-actor Task a chance to run.
        try? await Task.sleep(nanoseconds: 200_000_000)

        #expect(checkCount >= 1)
        #expect(installCount >= 1)

        let checksBeforeCancel = checkCount
        let installsBeforeCancel = installCount
        observer.cancel()
        NotificationCenter.postCheckForUpdates()
        NotificationCenter.postInstallPreparedAppUpdate()
        try? await Task.sleep(nanoseconds: 150_000_000)
        #expect(checkCount == checksBeforeCancel)
        #expect(installCount == installsBeforeCancel)
    }

    private struct MockReachability: FeedURLReachabilityChecking {
        let isReachable: Bool

        func isReachable(_ url: URL) async -> Bool {
            isReachable
        }
    }

    private final class CountingReachability: FeedURLReachabilityChecking, @unchecked Sendable {
        let isReachable: Bool
        var callCount = 0

        init(isReachable: Bool) {
            self.isReachable = isReachable
        }

        func isReachable(_ url: URL) async -> Bool {
            callCount += 1
            return isReachable
        }
    }
}

/// Minimal thread-safe boolean flag used to await async notification delivery.
final class _TestFlag: @unchecked Sendable {
    private var _value = false
    func set(_ value: Bool) {
        objc_sync_enter(self); defer { objc_sync_exit(self) }
        _value = value
    }
    func get() -> Bool {
        objc_sync_enter(self); defer { objc_sync_exit(self) }
        return _value
    }
}

func expectationBool() -> _TestFlag { _TestFlag() }

func waitUntil(_ flag: _TestFlag, timeout: TimeInterval = 2) async {
    let start = Date()
    while !flag.get() {
        if Date().timeIntervalSince(start) > timeout { break }
        try? await Task.sleep(nanoseconds: 20_000_000)
    }
}

final class _MutableClock: @unchecked Sendable {
    private var _now: Date
    init(start: Date) { _now = start }
    func now() -> Date {
        objc_sync_enter(self); defer { objc_sync_exit(self) }
        return _now
    }
    func advance(by seconds: TimeInterval) {
        objc_sync_enter(self); defer { objc_sync_exit(self) }
        _now = _now.addingTimeInterval(seconds)
    }
}

final class _StringBox: @unchecked Sendable {
    var value: String?
}
