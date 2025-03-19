/// GitOK - 通道管理器
///
/// 负责管理所有与原生平台的通信通道，包括：
/// - 日志通道：处理应用日志的发送和接收
/// - 窗口通道：处理窗口相关的原生操作
/// - 其他平台特定的通道
///
/// 设计原则：
/// 1. 统一管理所有的平台通道
/// 2. 只与 main.dart 交互，不直接与其他管理器通信
/// 3. 提供清晰的事件回调机制
/// 4. 统一的错误处理和日志记录
library;

import 'package:flutter/services.dart';
import 'package:gitok/utils/logger.dart';

/// 通道事件回调函数类型
typedef ChannelEventCallback = void Function(dynamic data);

/// 通道管理器
///
/// 统一管理所有与原生平台的通信通道，提供：
/// - 通道的初始化和销毁
/// - 消息的发送和接收
/// - 事件的订阅和取消订阅
/// - 统一的错误处理机制
class ChannelManager {
  static final ChannelManager _instance = ChannelManager._internal();
  factory ChannelManager() => _instance;
  ChannelManager._internal();

  static const String _tag = 'ChannelManager';

  // 日志通道
  static const MethodChannel _loggerChannel = MethodChannel('com.cofficlab.gitok/logger');

  // 窗口通道
  static const MethodChannel _windowChannel = MethodChannel('com.cofficlab.gitok/window');

  // 事件回调
  ChannelEventCallback? onNativeError;
  ChannelEventCallback? onWindowEvent;
  ChannelEventCallback? onOverlaidAppChanged;

  /// 通用方法调用
  Future<T?> _invokeMethod<T>(MethodChannel channel, String method, [dynamic arguments]) async {
    try {
      final result = await channel.invokeMethod<T>(method, arguments);
      return result;
    } catch (e) {
      Logger.error(_tag, '方法调用失败: $method', e);
      onNativeError?.call(e);
      rethrow;
    }
  }

  /// 包装处理器以添加统一的错误处理
  Future<dynamic> Function(MethodCall) _wrapHandler(
    Future<dynamic> Function(MethodCall) handler,
    String channelName,
  ) {
    return (MethodCall call) async {
      try {
        final result = await handler(call);
        return result;
      } catch (e) {
        final error = '$channelName处理失败: ${call.method} - $e';
        Logger.error(_tag, error);
        onNativeError?.call(error);
        rethrow;
      }
    };
  }

  /// 初始化所有通道
  Future<void> init() async {
    try {
      // 初始化日志通道
      _loggerChannel.setMethodCallHandler(
        _wrapHandler(_handleLoggerMethodCall, '日志通道'),
      );
      Logger.info(_tag, '日志通道初始化完成');

      // 初始化窗口通道
      _windowChannel.setMethodCallHandler(
        _wrapHandler(_handleWindowMethodCall, '窗口通道'),
      );
      Logger.info(_tag, '窗口通道初始化完成');

      Logger.info(_tag, '🎉 所有通道初始化完成');
    } catch (e) {
      Logger.error(_tag, '❌ 通道初始化失败: $e');
      onNativeError?.call(e);
    }
  }

  /// 处理日志通道的方法调用
  Future<dynamic> _handleLoggerMethodCall(MethodCall call) async {
    if (call.method == 'log') {
      // 确保类型转换正确
      final Map<Object?, Object?> rawArgs = call.arguments as Map<Object?, Object?>;
      final Map<String, dynamic> args = Map<String, dynamic>.from(rawArgs);

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

  /// 处理窗口通道的方法调用
  Future<dynamic> _handleWindowMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onWindowEvent':
        onWindowEvent?.call(call.arguments);
        break;
      case 'updateOverlaidApp':
        final Map<String, dynamic>? appInfo =
            call.arguments != null ? Map<String, dynamic>.from(call.arguments as Map) : null;
        onOverlaidAppChanged?.call(appInfo);
        break;
      default:
        throw PlatformException(
          code: 'not_implemented',
          message: '未实现的窗口方法: ${call.method}',
        );
    }
  }

  /// 发送日志到原生平台
  Future<void> sendLog(String level, String message, {String tag = 'App'}) async {
    await _invokeMethod(_loggerChannel, 'log', {
      'level': level,
      'message': message,
      'tag': tag,
    });
  }

  /// 更新被覆盖的应用信息
  Future<void> updateOverlaidApp(Map<String, dynamic>? appInfo) async {
    await _invokeMethod(_windowChannel, 'updateOverlaidApp', appInfo);
  }

  /// 获取被覆盖的应用信息
  Future<Map<String, dynamic>?> getOverlaidApp() async {
    try {
      return await _invokeMethod(_windowChannel, 'getOverlaidApp');
    } catch (e) {
      Logger.error(_tag, '获取覆盖应用信息失败: $e');
      onNativeError?.call(e);
      return null;
    }
  }

  /// 清理资源
  void dispose() {
    // 清理所有通道的资源
    _loggerChannel.setMethodCallHandler(null);
    _windowChannel.setMethodCallHandler(null);
    Logger.info(_tag, '所有通道已清理');
  }
}
