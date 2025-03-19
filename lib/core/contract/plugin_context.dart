/// 插件上下文
///
/// 提供插件运行时需要的上下文信息，包括：
/// 1. 当前工作区路径
/// 2. 当前覆盖的应用信息
/// 3. 其他全局信息
class PluginContext {
  /// 当前工作区路径
  final String? workspace;

  /// 当前覆盖的应用名称
  final String? overlaidAppName;

  /// 当前覆盖的应用包名
  final String? overlaidAppBundleId;

  /// 当前覆盖的应用进程ID
  final int? overlaidAppProcessId;

  const PluginContext({
    this.workspace,
    this.overlaidAppName,
    this.overlaidAppBundleId,
    this.overlaidAppProcessId,
  });

  /// 创建一个空的上下文
  static const empty = PluginContext();

  /// 判断是否有工作区
  bool get hasWorkspace => workspace != null;

  /// 判断是否有覆盖的应用
  bool get hasOverlaidApp => overlaidAppName != null;
}
