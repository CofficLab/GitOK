/// GitOK - 快捷键管理器
///
/// 负责管理应用程序的全局快捷键功能，包括快捷键的注册、
/// 注销和事件处理等。
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:gitok/core/managers/tray_manager.dart';

/// 快捷键管理器类
///
/// 封装了所有与快捷键相关的功能，包括：
/// - 快捷键的注册和注销
/// - 快捷键事件的处理
/// - 全局快捷键的管理
class AppHotkeyManager {
  static final AppHotkeyManager _instance = AppHotkeyManager._internal();
  factory AppHotkeyManager() => _instance;
  AppHotkeyManager._internal();

  final _trayManager = AppTrayManager();

  /// 初始化快捷键管理器
  Future<void> init() async {
    // 对于热重载，`unregisterAll()` 需要被调用
    await hotKeyManager.unregisterAll();

    // 设置键盘监听器
    RawKeyboard.instance.addListener(_onKey);

    // 注册全局快捷键
    await _setupGlobalHotkey();
  }

  /// 设置全局热键，用于将应用从后台唤醒到前台
  Future<void> _setupGlobalHotkey() async {
    // 为了兼容性，我们保留Alt+1热键
    final altHotKey = HotKey(
      key: LogicalKeyboardKey.digit1,
      modifiers: [HotKeyModifier.alt],
      scope: HotKeyScope.system,
    );

    // 使用Command+D作为备用快捷键
    final cmdDHotKey = HotKey(
      key: LogicalKeyboardKey.keyD,
      modifiers: [HotKeyModifier.meta], // Command键
      scope: HotKeyScope.system,
    );

    try {
      // 注册Alt+1热键
      await hotKeyManager.register(
        altHotKey,
        keyDownHandler: (hotKey) async {
          if (kDebugMode) {
            print('Alt+1 热键被触发');
          }
          await _trayManager.bringToFront();
        },
      );

      // 注册Command+D热键
      await hotKeyManager.register(
        cmdDHotKey,
        keyDownHandler: (hotKey) async {
          if (kDebugMode) {
            print('Command+D 热键被触发');
          }
          await _trayManager.bringToFront();
        },
      );

      BotToast.showText(text: '已注册全局热键：双击⌘、⌘+D 或 Alt+1 可将应用带到前台');
    } catch (e) {
      BotToast.showText(text: '注册全局热键失败: $e');
      if (kDebugMode) {
        print('注册全局热键失败: $e');
      }
    }
  }

  /// 处理键盘事件
  void _onKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _trayManager.hide();
      }
    }
  }

  /// 注销所有快捷键
  Future<void> dispose() async {
    // 移除键盘监听器
    RawKeyboard.instance.removeListener(_onKey);
    // 注销所有热键
    await hotKeyManager.unregisterAll();
  }
}
