import Foundation
import KitGitOKUpdate
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

    private struct MockReachability: FeedURLReachabilityChecking {
        let isReachable: Bool

        func isReachable(_ url: URL) async -> Bool {
            isReachable
        }
    }
}
