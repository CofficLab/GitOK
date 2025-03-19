import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// 日志工具类
///
/// 提供统一的日志记录功能：
/// 1. 不同级别的日志输出（info、error、debug）
/// 2. 支持日志标签，方便追踪日志来源
/// 3. 在调试模式下自动添加表情符号提高可读性
/// 4. 使用 dart:developer 确保更好的开发体验
class Logger {
  const Logger._();

  /// 记录信息日志
  ///
  /// [tag] 日志标签，用于标识日志来源
  /// [message] 日志消息
  static void info(String tag, String message) {
    final logMessage = '[$tag] $message';
    if (kDebugMode) {
      print('ℹ️ $logMessage');
    }
    developer.log(logMessage, name: 'INFO');
  }

  /// 记录错误日志
  ///
  /// [tag] 日志标签，用于标识日志来源
  /// [message] 错误消息
  /// [error] 错误对象（可选）
  static void error(String tag, String message, [dynamic error]) {
    final logMessage = '[$tag] $message';
    if (kDebugMode) {
      print('❌ $logMessage');
      if (error != null) {
        print('   $error');
      }
    }
    developer.log('$logMessage${error != null ? '\n$error' : ''}', name: 'ERROR');
  }

  /// 记录调试日志（仅在调试模式下）
  ///
  /// [tag] 日志标签，用于标识日志来源
  /// [message] 调试消息
  static void debug(String tag, String message) {
    if (kDebugMode) {
      print('🔍 [$tag] $message');
      developer.log('[$tag] $message', name: 'DEBUG');
    }
  }
}
