/// GitOK - 窗口管理器
///
/// 负责管理应用程序的窗口功能，包括窗口的初始化、配置、
/// 显示、隐藏等操作。
library;

import 'dart:io' show Platform, exit;
import 'package:flutter/material.dart';
import 'package:macos_window_utils/macos_window_utils.dart';
import 'package:window_manager/window_manager.dart' as win;
import 'package:gitok/utils/logger.dart';

/// 窗口事件回调函数类型
typedef WindowEventCallback = void Function();

/// 窗口监听器类
///
/// 用于处理窗口事件的回调
class WindowListener {
  /// 当窗口关闭时调用
  void onWindowClose() {}

  /// 当窗口获得焦点时调用
  void onWindowFocus() {}

  /// 当窗口失去焦点时调用
  void onWindowBlur() {}

  /// 当窗口最大化时调用
  void onWindowMaximize() {}

  /// 当窗口取消最大化时调用
  void onWindowUnmaximize() {}

  /// 当窗口最小化时调用
  void onWindowMinimize() {}

  /// 当窗口恢复时调用
  void onWindowRestore() {}

  /// 当窗口移动时调用
  void onWindowMove() {}

  /// 当窗口调整大小时调用
  void onWindowResize() {}
}

/// 窗口管理器类
///
/// 封装了所有与窗口相关的功能，包括：
/// - 窗口的初始化
/// - 窗口的配置
/// - 窗口的显示和隐藏
/// - 平台特定的窗口处理
class AppWindowManager with win.WindowListener {
  static final AppWindowManager _instance = AppWindowManager._internal();
  factory AppWindowManager() => _instance;
  AppWindowManager._internal();

  final List<WindowListener> _listeners = [];

  // 事件回调
  WindowEventCallback? onWindowHidden;
  WindowEventCallback? onWindowShown;
  WindowEventCallback? onWindowFocused;
  WindowEventCallback? onQuitRequested;

  /// 初始化窗口管理器
  Future<void> init() async {
    Logger.info('WindowManager', '开始初始化窗口管理器');

    // 初始化window_manager
    await win.windowManager.ensureInitialized();

    // 设置窗口选项
    win.WindowOptions windowOptions = const win.WindowOptions(
      size: Size(1200, 600),
      center: true,
      title: "GitOk",
      alwaysOnTop: false,
    );

    // 注册窗口事件监听器
    win.windowManager.addListener(this);
    Logger.info('WindowManager', '已注册窗口事件监听器');

    await win.windowManager.waitUntilReadyToShow(windowOptions, () async {
      await win.windowManager.show();
      await win.windowManager.focus();
    });

    // 如果是 macOS 平台，我们需要特殊照顾一下它的窗口 ✨
    if (Platform.isMacOS) {
      await WindowManipulator.initialize();
      WindowManipulator.makeTitlebarTransparent();
      WindowManipulator.enableFullSizeContentView();
      WindowManipulator.hideTitle();
    }

    Logger.info('WindowManager', '窗口管理器初始化完成');
  }

  /// 隐藏窗口
  Future<void> hide() async {
    Logger.info('WindowManager', '准备隐藏窗口');
    await win.windowManager.hide();
    Logger.info('WindowManager', '窗口已隐藏，调用回调');
    onWindowHidden?.call();
  }

  /// 显示窗口
  Future<void> show() async {
    Logger.info('WindowManager', '准备显示窗口');
    await win.windowManager.show();
    Logger.info('WindowManager', '窗口已显示，调用回调');
    onWindowShown?.call();
  }

  /// 将窗口带到前台
  Future<void> focus() async {
    Logger.info('WindowManager', '准备将窗口带到前台');
    await win.windowManager.focus();
    Logger.info('WindowManager', '窗口已带到前台，调用回调');
    onWindowFocused?.call();
  }

  /// 添加窗口监听器
  void addListener(WindowListener listener) {
    _listeners.add(listener);
  }

  /// 移除窗口监听器
  void removeListener(WindowListener listener) {
    _listeners.remove(listener);
  }

  /// 退出应用
  Future<void> quit() async {
    onQuitRequested?.call();
    await win.windowManager.close();
    exit(0);
  }

  /// 清理资源
  void dispose() {
    Logger.info('WindowManager', '清理窗口管理器资源');
    win.windowManager.removeListener(this);
    _listeners.clear();
  }

  @override
  void onWindowClose() {
    Logger.info('WindowManager', '收到窗口关闭事件');
    for (final listener in _listeners) {
      listener.onWindowClose();
    }
  }

  @override
  void onWindowFocus() {
    Logger.info('WindowManager', '收到窗口获得焦点事件');
    for (final listener in _listeners) {
      listener.onWindowFocus();
    }
  }

  @override
  void onWindowBlur() {
    Logger.info('WindowManager', '收到窗口失去焦点事件');
    for (final listener in _listeners) {
      listener.onWindowBlur();
    }
  }

  @override
  void onWindowMaximize() {
    Logger.info('WindowManager', '收到窗口最大化事件');
    for (final listener in _listeners) {
      listener.onWindowMaximize();
    }
  }

  @override
  void onWindowUnmaximize() {
    Logger.info('WindowManager', '收到窗口取消最大化事件');
    for (final listener in _listeners) {
      listener.onWindowUnmaximize();
    }
  }

  @override
  void onWindowMinimize() {
    Logger.info('WindowManager', '收到窗口最小化事件');
    for (final listener in _listeners) {
      listener.onWindowMinimize();
    }
  }

  @override
  void onWindowRestore() {
    Logger.info('WindowManager', '收到窗口恢复事件');
    for (final listener in _listeners) {
      listener.onWindowRestore();
    }
  }

  @override
  void onWindowMove() {
    for (final listener in _listeners) {
      listener.onWindowMove();
    }
  }

  @override
  void onWindowResize() {
    for (final listener in _listeners) {
      listener.onWindowResize();
    }
  }
}
