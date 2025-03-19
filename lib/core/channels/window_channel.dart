import 'package:flutter/services.dart';
import 'method_channel_manager.dart';

/// 窗口通道管理器
///
/// 负责管理与原生平台之间关于窗口操作的通信。
/// 包括窗口的显示、隐藏、激活等操作。
class WindowChannel extends MethodChannelManager {
  WindowChannel._();
  static final WindowChannel instance = WindowChannel._();

  @override
  final channel = const MethodChannel('com.cofficlab.gitok/window');

  /// 更新被覆盖的应用信息
  Future<void> updateOverlaidApp(Map<String, dynamic>? appInfo) {
    return invokeMethod('updateOverlaidApp', appInfo);
  }

  /// 获取被覆盖的应用信息
  Future<Map<String, dynamic>?> getOverlaidApp() async {
    final result = await invokeMethod('getOverlaidApp');
    return result as Map<String, dynamic>?;
  }
}
