/// GitOK - 更新管理器
///
/// 负责管理应用程序的自动更新功能，包括检查更新、
/// 下载更新、安装更新等操作。
library;

import 'dart:io' show Platform;
import 'package:auto_updater/auto_updater.dart';
import 'package:gitok/core/config/app_config.dart';

/// 更新管理器类
///
/// 封装了所有与自动更新相关的功能，包括：
/// - 检查更新
/// - 下载更新
/// - 安装更新
class AppUpdateManager {
  static final AppUpdateManager _instance = AppUpdateManager._internal();
  factory AppUpdateManager() => _instance;
  AppUpdateManager._internal();

  /// 初始化更新管理器
  Future<void> init() async {
    if (Platform.isMacOS || Platform.isWindows) {
      // 设置更新源地址
      await autoUpdater.setFeedURL(await AutoUpdateConfig.feedURL);

      // 设置检查更新的时间间隔
      await autoUpdater.setScheduledCheckInterval(await AutoUpdateConfig.checkInterval);

      // 应用启动时检查一次更新
      await autoUpdater.checkForUpdates();
    }
  }

  /// 手动检查更新
  Future<void> checkForUpdates() async {
    if (Platform.isMacOS || Platform.isWindows) {
      await autoUpdater.checkForUpdates();
    }
  }
}
