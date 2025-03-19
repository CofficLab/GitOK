import 'dart:io' show Platform;
import 'package:auto_updater/auto_updater.dart';
import 'package:gitok/core/config/app_config.dart';
import 'package:flutter/foundation.dart';

/// 更新管理器类
///
/// 封装了所有与自动更新相关的功能，包括：
/// - 检查更新
/// - 下载更新
/// - 安装更新
///
/// 使用了这个第三方库：https://github.com/leanflutter/auto_updater
/// 这个插件允许 Flutter 桌面 应用自动更新自己 (基于 sparkle 和 winsparkle)。
class AppUpdateManager {
  static final AppUpdateManager _instance = AppUpdateManager._internal();
  factory AppUpdateManager() => _instance;
  AppUpdateManager._internal();

  /// 更新状态监听器
  final updateStateNotifier = ValueNotifier<String>('');

  /// 初始化更新管理器
  Future<void> init() async {
    if (Platform.isMacOS || Platform.isWindows) {
      // 设置更新源地址
      await autoUpdater.setFeedURL(await AutoUpdateConfig.feedURL);

      // 设置检查更新的时间间隔
      await autoUpdater.setScheduledCheckInterval(await AutoUpdateConfig.checkInterval);

      // 应用启动时检查一次更新
      await checkForUpdates();
    }
  }

  /// 手动检查更新
  Future<void> checkForUpdates() async {
    if (Platform.isMacOS || Platform.isWindows) {
      try {
        await autoUpdater.checkForUpdates(inBackground: true);
      } catch (e) {
        // 静默处理错误，不显示弹窗
        if (kDebugMode) {
          print('检查更新失败: $e');
        }
      }
    }
  }
}
