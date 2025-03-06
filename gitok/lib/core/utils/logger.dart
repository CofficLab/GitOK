import 'dart:developer' as developer;

/// 日志工具类
class Logger {
  void info(String message) {
    developer.log(message, name: 'INFO');
  }

  void error(String message, [dynamic error]) {
    developer.log('$message${error != null ? '\n$error' : ''}', name: 'ERROR');
  }
}
