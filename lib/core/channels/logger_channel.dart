import 'package:flutter/services.dart';
import 'package:gitok/utils/logger.dart';
import 'method_channel_manager.dart';

/// 日志通道管理器
///
/// 负责管理与原生平台之间的日志通信。
/// 接收来自原生平台的日志并通过 Logger 类统一处理。
class LoggerChannel extends MethodChannelManager {
  static const String _tag = 'LoggerChannel';

  LoggerChannel._() {
    Logger.debug(_tag, '创建日志通道实例');
    // 设置方法调用处理器
    setMethodCallHandler(_handleMethodCall);
    Logger.info(_tag, '日志通道初始化完成');
  }

  static final LoggerChannel instance = LoggerChannel._();

  @override
  final channel = const MethodChannel('com.cofficlab.gitok/logger');

  /// 处理来自原生端的日志
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'log') {
      final Map args = call.arguments as Map;
      final String message = args['message'] as String;
      final String level = args['level'] as String;
      final String tag = args['tag'] as String;

      switch (level) {
        case 'debug':
          Logger.debug(tag, message);
          break;
        case 'error':
          Logger.error(tag, message);
          break;
        default:
          Logger.info(tag, message);
          break;
      }
    }
  }
}
