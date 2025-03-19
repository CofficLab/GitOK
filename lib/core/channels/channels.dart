/// 通道管理
///
/// 导出所有通道管理器，方便统一导入。
/// 包括：
/// 1. 窗口通道 - 管理窗口相关操作
/// 2. 日志通道 - 管理日志传输
/// 3. 基础通道管理器 - 提供通道管理的基础功能
library channels;

export 'method_channel_manager.dart';
export 'window_channel.dart';
export 'logger_channel.dart';
