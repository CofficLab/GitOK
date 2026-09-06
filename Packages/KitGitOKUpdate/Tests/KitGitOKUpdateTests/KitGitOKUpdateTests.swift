import Foundation
import KitGitOKUpdate
import Testing

@Suite("KitGitOKUpdate")
struct KitGitOKUpdateTests {
    @Test("uses GitOK feed hosts")
    func feedHosts() {
        #expect(UpdateFeedURLProvider.primary(forArchitecture: "arm64").host == "api.kuaiyizhi.cn")
        #expect(UpdateFeedURLProvider.primary(forArchitecture: "x86_64").lastPathComponent == "appcast-x86_64.xml")
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

    private struct MockReachability: FeedURLReachabilityChecking {
        let isReachable: Bool

        func isReachable(_ url: URL) async -> Bool {
            isReachable
        }
    }
}
