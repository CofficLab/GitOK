import Foundation
import KitGitOKLocalization

/// FactoryGitOK 暴露的本地化入口。
///
/// App target（`GitOKApp`）不直接依赖 `KitGitOKLocalization`，
/// 而是通过这里获得 App 层文案的本地化结果。
public enum GitOKAppLocalization {
    /// FactoryGitOK 模块的资源 bundle。
    private static let bundle = Bundle.module

    /// 本地化 App 层文案。
    ///
    /// 未命中时回退为原始 key，保证 UI 不会空白。
    public static func string(_ key: String) -> String {
        GitOKLocalization.string(key, bundle: bundle)
    }

    /// 当前生效的界面语言标识。
    public static var effectiveLanguageCode: String {
        GitOKLocalization.effectiveLanguageCode
    }
}
