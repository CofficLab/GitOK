import Foundation

/// GitOK 的 Sparkle feed 地址。
///
/// 发布工作流会把同一份 appcast 发布到 GitOK 自有更新服务和 GitHub Release，
/// 运行时优先使用自有服务，网络不可达时回退到 GitHub。
public enum UpdateFeedURLProvider {
    public static var primary: URL {
        primary(forArchitecture: currentArchitecture)
    }

    public static var fallback: URL {
        fallback(forArchitecture: currentArchitecture)
    }

    public static func primary(forArchitecture architecture: String) -> URL {
        precondition(
            architecture == "arm64" || architecture == "x86_64",
            "Unsupported architecture: \(architecture)"
        )
        return URL(
            string: "https://api.kuaiyizhi.cn/gitok/appcast-\(architecture).xml"
        )!
    }

    public static func fallback(forArchitecture architecture: String) -> URL {
        precondition(
            architecture == "arm64" || architecture == "x86_64",
            "Unsupported architecture: \(architecture)"
        )
        return URL(
            string: "https://github.com/CofficLab/GitOK/releases/latest/download/appcast-\(architecture).xml"
        )!
    }

    private static var currentArchitecture: String {
        #if arch(arm64)
        return "arm64"
        #else
        return "x86_64"
        #endif
    }
}
