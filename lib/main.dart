import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:macos_window_utils/macos_window_utils.dart';
import 'package:gitok/core/layouts/app.dart';
import 'package:window_manager/window_manager.dart';
import 'package:auto_updater/auto_updater.dart';
import 'package:gitok/core/config/app_config.dart';
import 'package:gitok/core/managers/tray_manager.dart';

/// GitOK - Git仓库管理工具
///
/// 这是应用程序的入口文件，负责初始化应用并配置基础设置。
/// 包括平台检测、窗口配置等全局设置。
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化自动更新
  if (Platform.isMacOS || Platform.isWindows) {
    // 设置更新源地址
    await autoUpdater.setFeedURL(await AutoUpdateConfig.feedURL);

    // 设置检查更新的时间间隔
    await autoUpdater.setScheduledCheckInterval(await AutoUpdateConfig.checkInterval);

    // 应用启动时检查一次更新
    await autoUpdater.checkForUpdates();
  }

  // 初始化window_manager
  await windowManager.ensureInitialized();

  // 设置窗口选项
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1200, 600),
    center: true,
    title: "GitOk",
    alwaysOnTop: false,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // 对于热重载，`unregisterAll()` 需要被调用。
  await hotKeyManager.unregisterAll();

  // 如果是 macOS 平台，我们需要特殊照顾一下它的窗口 ✨
  if (Platform.isMacOS) {
    await WindowManipulator.initialize();
    WindowManipulator.makeTitlebarTransparent();
    WindowManipulator.enableFullSizeContentView();
    WindowManipulator.hideTitle();
  }

  // 初始化托盘管理器
  await AppTrayManager().init();

  runApp(const MyApp());
}
