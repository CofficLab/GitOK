/// GitOK - 托盘管理器
///
/// 负责管理应用程序的系统托盘功能，包括托盘图标的显示、隐藏、
/// 菜单项的点击处理等。
library;

import 'dart:io' show Platform, exit;
import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart' as tray;
import 'package:window_manager/window_manager.dart';
import 'package:bot_toast/bot_toast.dart';

/// 托盘管理器类
///
/// 封装了所有与系统托盘相关的功能，包括：
/// - 托盘图标的显示和隐藏
/// - 托盘菜单的创建和管理
/// - 托盘事件的监听和处理
class AppTrayManager {
  static final AppTrayManager _instance = AppTrayManager._internal();
  factory AppTrayManager() => _instance;
  AppTrayManager._internal();

  /// 初始化托盘管理器
  Future<void> init() async {
    await tray.trayManager.setIcon(
      Platform.isMacOS
          ? 'assets/app_icon.png' // macOS 图标路径
          : 'assets/app_icon_win.png', // Windows 图标路径
    );

    // 创建托盘菜单
    await tray.trayManager.setContextMenu(
      tray.Menu(
        items: [
          tray.MenuItem(
            key: 'show_window',
            label: '打开 GitOK',
          ),
          tray.MenuItem.separator(),
          tray.MenuItem(
            key: 'exit_app',
            label: '退出',
          ),
        ],
      ),
    );
  }

  /// 将窗口带到前台
  Future<void> bringToFront() async {
    try {
      await windowManager.show();
      await windowManager.focus();
      BotToast.showText(text: '应用已成功回到前台');
    } catch (e) {
      debugPrint('将窗口带到前台失败: $e');
    }
  }

  /// 处理托盘菜单点击事件
  void onTrayMenuItemClick(tray.MenuItem menuItem) {
    if (menuItem.key == 'show_window') {
      bringToFront();
    } else if (menuItem.key == 'exit_app') {
      exit(0);
    }
  }

  /// 处理托盘图标点击事件
  void onTrayIconMouseDown() {
    if (Platform.isMacOS) {
      tray.trayManager.popUpContextMenu();
    } else {
      bringToFront();
    }
  }

  /// 处理托盘图标右键点击事件
  void onTrayIconRightMouseDown() {
    tray.trayManager.popUpContextMenu();
  }
}
