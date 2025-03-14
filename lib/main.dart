import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:gitok/core/layouts/app.dart';
import 'package:auto_updater/auto_updater.dart';
import 'package:gitok/core/config/app_config.dart';
import 'package:gitok/core/managers/tray_manager.dart';
import 'package:gitok/core/managers/window_manager.dart';

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

  // 对于热重载，`unregisterAll()` 需要被调用。
  await hotKeyManager.unregisterAll();

  // 初始化窗口管理器
  await AppWindowManager().init();

  // 初始化托盘管理器
  await AppTrayManager().init();

  runApp(const MyApp());
}
