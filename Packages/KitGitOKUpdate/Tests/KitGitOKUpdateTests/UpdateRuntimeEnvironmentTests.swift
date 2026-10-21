import Foundation
import Testing
@testable import KitGitOKUpdate

/// `UpdateFeedURLProvider` 的运行时地址覆盖。
@Suite("UpdateFeedURLProvider 运行时地址")
struct UpdateFeedURLProviderRuntimeTests {

    @Test("primary/fallback 使用当前架构")
    func primaryAndFallbackUseCurrentArchitecture() {
        #expect(UpdateFeedURLProvider.primary.host == "api.kuaiyizhi.cn")
        #expect(UpdateFeedURLProvider.primary.path == "/gitok/appcast.xml")
        #expect(UpdateFeedURLProvider.fallback.host == "github.com")
        #expect(UpdateFeedURLProvider.fallback.path.hasPrefix("/CofficLab/GitOK/releases/latest/download/appcast-"))
        #expect(UpdateFeedURLProvider.fallback.path.hasSuffix(".xml"))
    }

    @Test("primary 的 arch 查询参数与当前架构一致")
    func primaryCarriesArchitectureQueryItem() throws {
        let components = try #require(
            URLComponents(url: UpdateFeedURLProvider.primary, resolvingAgainstBaseURL: false)
        )
        let item = try #require(components.queryItems?.first { $0.name == "arch" })
        #expect(item.value == "arm64" || item.value == "x86_64")
    }
}

/// `URLSessionFeedURLReachabilityChecker` 的探测行为覆盖。
@Suite("URLSessionFeedURLReachabilityChecker")
struct FeedURLReachabilityCheckerTests {

    @Test("默认超时为 5 秒，可自定义")
    func timeoutIsConfigurable() {
        #expect(URLSessionFeedURLReachabilityChecker().timeout == 5)
        #expect(URLSessionFeedURLReachabilityChecker(timeout: 1.5).timeout == 1.5)
    }

    @Test("不可达的地址返回 false")
    func unreachableURLReturnsFalse() async {
        let checker = URLSessionFeedURLReachabilityChecker(timeout: 1)
        // 保留端口 9（discard）几乎不可能有服务在监听，连接必然失败。
        let unreachable = URL(string: "http://127.0.0.1:9/appcast.xml")!

        let reachable = await checker.isReachable(unreachable)

        #expect(reachable == false)
    }
}

/// `AppUpdateBootstrap` 的启停覆盖。
@Suite("AppUpdateBootstrap")
@MainActor
struct AppUpdateBootstrapTests {

    @Test("start 注册请求观察者，stop 取消它")
    func startAndStopAreIdempotent() {
        AppUpdateBootstrap.start()
        AppUpdateBootstrap.start()
        AppUpdateBootstrap.stop()
        AppUpdateBootstrap.stop()
    }
}

/// `UpdateService` 中不依赖 Sparkle 实例的部分。
@Suite("UpdateService 无 Sparkle 依赖路径")
@MainActor
struct UpdateServiceSafePathsTests {

    @Test("共享实例可用，初始状态为空闲")
    func sharedServiceStartsIdle() async {
        let service = UpdateService.shared

        let state = await service.currentState
        let version = await service.latestVersion

        #expect(state == .idle)
        #expect(version == nil)
    }

    @Test("DEBUG 构建下检查更新请求被环境开关拦截")
    func checkForUpdatesIsGatedByEnvironment() async {
        let service = UpdateService.shared

        // 测试进程处于 DEBUG 构建，allowsAppUpdates 为 false，
        // 因此不会触碰 Sparkle 的 SPUUpdater。
        service.checkForUpdates()
        service.handleCheckForUpdatesRequest()
        service.handleInstallPreparedAppUpdateRequest()

        let state = await service.currentState
        #expect(state == .idle)
    }

    @Test("已构建的更新器控制器在环境开关关闭时保持为空")
    func updaterControllerStaysNilWhenUpdatesDisabled() {
        let service = UpdateService.shared

        // 环境开关关闭时直接返回，不会创建 Sparkle 的 SPUStandardUpdaterController。
        service.ensureUpdaterInitialized()

        #expect(service.updaterController == nil)
        #expect(service.updater == nil)
    }
}
