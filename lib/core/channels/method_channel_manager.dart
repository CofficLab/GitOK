import 'package:flutter/services.dart';
import 'package:gitok/utils/logger.dart';

/// 方法通道管理器
///
/// 负责管理与原生平台之间的方法通道通信。
/// 提供了通道的基本操作和错误处理。
abstract class MethodChannelManager {
  static const String _tag = 'MethodChannelManager';

  /// 获取方法通道
  MethodChannel get channel;

  /// 调用方法
  Future<T?> invokeMethod<T>(String method, [dynamic arguments]) async {
    try {
      Logger.debug(_tag, '调用方法: $method, 参数: $arguments');
      final result = await channel.invokeMethod<T>(method, arguments);
      Logger.debug(_tag, '方法调用成功: $method, 结果: $result');
      return result;
    } catch (e) {
      Logger.error(_tag, '方法调用失败: $method', e);
      rethrow;
    }
  }

  /// 设置方法调用处理器
  void setMethodCallHandler(Future<dynamic> Function(MethodCall call)? handler) {
    channel.setMethodCallHandler(handler != null ? _wrapHandler(handler) : null);
  }

  /// 包装处理器以添加日志
  Future<dynamic> Function(MethodCall) _wrapHandler(
    Future<dynamic> Function(MethodCall) handler,
  ) {
    return (MethodCall call) async {
      try {
        Logger.debug(_tag, '收到方法调用: ${call.method}, 参数: ${call.arguments}');
        final result = await handler(call);
        Logger.debug(_tag, '方法处理成功: ${call.method}, 结果: $result');
        return result;
      } catch (e) {
        Logger.error(_tag, '方法处理失败: ${call.method}', e);
        rethrow;
      }
    };
  }
}
