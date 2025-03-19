import 'package:flutter/material.dart';
import 'package:bot_toast/bot_toast.dart';

/// Toast 消息工具类
///
/// 提供统一的消息提示功能，包括：
/// 1. 成功消息
/// 2. 错误消息
/// 3. 警告消息
/// 4. 信息提示
class ToastUtils {
  /// 显示成功消息
  static void success(String message) {
    _showToast(
      message,
      backgroundColor: Colors.green,
      icon: Icons.check_circle,
    );
  }

  /// 显示错误消息
  static void error(String message) {
    _showToast(
      message,
      backgroundColor: Colors.red,
      icon: Icons.error,
    );
  }

  /// 显示警告消息
  static void warning(String message) {
    _showToast(
      message,
      backgroundColor: Colors.orange,
      icon: Icons.warning,
    );
  }

  /// 显示信息提示
  static void info(String message) {
    _showToast(
      message,
      backgroundColor: Colors.blue,
      icon: Icons.info,
    );
  }

  /// 显示 Toast 消息
  static void _showToast(
    String message, {
    required Color backgroundColor,
    required IconData icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    BotToast.showCustomNotification(
      duration: duration,
      toastBuilder: (cancel) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                offset: const Offset(0, 2),
                blurRadius: 4.0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12.0),
              Flexible(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
