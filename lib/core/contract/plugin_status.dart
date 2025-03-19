/// 插件状态
///
/// 用于描述插件当前的状态信息，包括：
/// 1. 状态文本
/// 2. 是否为错误状态
/// 3. 进度信息（可选）
class PluginStatus {
  /// 状态文本
  final String message;

  /// 是否为错误状态
  final bool isError;

  /// 进度值（0.0 到 1.0），null 表示无进度
  final double? progress;

  const PluginStatus({
    required this.message,
    this.isError = false,
    this.progress,
  });

  /// 创建一个普通状态
  static PluginStatus info(String message, {double? progress}) => PluginStatus(message: message, progress: progress);

  /// 创建一个错误状态
  static PluginStatus error(String message) => PluginStatus(message: message, isError: true);
}
