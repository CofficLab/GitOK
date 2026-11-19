import Foundation
import KitGitOKLocalization

/// App 层文案的本地化入口（绑定主 bundle 的 Localizable 目录）。
///
/// 走 `GitOKLocalization` 解析链：支持应用内语言覆盖，未命中回退原始 key。
let appLocalization = PluginLocalization(bundle: .main)