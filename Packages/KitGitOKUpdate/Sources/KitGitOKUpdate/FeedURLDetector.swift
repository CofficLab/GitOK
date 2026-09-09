import Foundation

/// 用于选择可访问 Sparkle feed 的可注入探测器。
public protocol FeedURLReachabilityChecking: Sendable {
    func isReachable(_ url: URL) async -> Bool
}

/// 使用 HEAD 请求探测更新 feed。
public struct URLSessionFeedURLReachabilityChecker: FeedURLReachabilityChecking {
    public let timeout: TimeInterval

    public init(timeout: TimeInterval = 5) {
        self.timeout = timeout
    }

    public func isReachable(_ url: URL) async -> Bool {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = timeout

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
                return false
            }
            return (200..<300).contains(statusCode)
        } catch {
            return false
        }
    }
}

/// 负责 primary → fallback 的 feed 选择，并缓存探测结果。
public actor FeedURLDetector {
    public static let defaultCacheWindow: TimeInterval = 30 * 60

    public private(set) var resolvedFeedURL: URL

    private var lastDetectionTime: Date?
    private let primaryURL: URL
    private let fallbackURL: URL
    private let reachabilityChecker: any FeedURLReachabilityChecking
    private let cacheWindow: TimeInterval
    private let clock: @Sendable () -> Date

    public init(
        initialURL: URL,
        reachabilityChecker: any FeedURLReachabilityChecking,
        fallbackURL: URL = UpdateFeedURLProvider.fallback,
        cacheWindow: TimeInterval = FeedURLDetector.defaultCacheWindow,
        clock: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.resolvedFeedURL = initialURL
        self.primaryURL = initialURL
        self.fallbackURL = fallbackURL
        self.reachabilityChecker = reachabilityChecker
        self.cacheWindow = cacheWindow
        self.clock = clock
    }

    public func detectIfNeeded() async {
        if let lastDetectionTime,
           clock().timeIntervalSince(lastDetectionTime) < cacheWindow {
            return
        }

        lastDetectionTime = clock()
        resolvedFeedURL = await Self.detectFeedURL(
            primary: primaryURL,
            fallback: fallbackURL,
            reachabilityChecker: reachabilityChecker
        )
    }

    public func forceRedetect() async {
        lastDetectionTime = nil
        await detectIfNeeded()
    }

    static func detectFeedURL(
        primary: URL,
        fallback: URL,
        reachabilityChecker: any FeedURLReachabilityChecking
    ) async -> URL {
        if await reachabilityChecker.isReachable(primary) {
            return primary
        }
        return fallback
    }
}
