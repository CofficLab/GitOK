import Foundation
import KitGitOKLocalization

/// PluginActivityHeatmap 的运行时本地化。
///
/// 委托 `GitOKLocalization` 按插件 bundle 的 Localizable 表查找，
/// 源语言为英语（en），并随系统语言偏好回退到 `.xcstrings` catalog。
public let pluginLocalization = PluginLocalization(bundle: .module)
