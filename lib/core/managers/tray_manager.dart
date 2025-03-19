import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart' as tray;
import 'package:bot_toast/bot_toast.dart';

/// 托盘事件回调函数类型
typedef TrayEventCallback = void Function();

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

  // 事件回调
  TrayEventCallback? onShowWindowRequested;
  TrayEventCallback? onQuitRequested;

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

  /// 更新托盘图标状态
  void updateTrayIcon({required bool isWindowVisible}) {
    // 这里可以根据窗口状态更新托盘图标
    // 例如：可以在窗口隐藏时显示不同的图标
  }

  /// 处理托盘菜单点击事件
  void onTrayMenuItemClick(tray.MenuItem menuItem) {
    if (menuItem.key == 'show_window') {
      onShowWindowRequested?.call();
    } else if (menuItem.key == 'exit_app') {
      onQuitRequested?.call();
    }
  }

  /// 处理托盘图标点击事件
  void onTrayIconMouseDown() {
    if (Platform.isMacOS) {
      tray.trayManager.popUpContextMenu();
    } else {
      onShowWindowRequested?.call();
    }
  }

  /// 处理托盘图标右键点击事件
  void onTrayIconRightMouseDown() {
    tray.trayManager.popUpContextMenu();
  }

  /// 清理资源
  void dispose() {
    // 清理托盘相关资源
    tray.trayManager.destroy();
  }
}
