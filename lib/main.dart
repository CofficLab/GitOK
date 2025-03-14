import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:gitok/core/layouts/app.dart';
import 'package:gitok/core/managers/tray_manager.dart';
import 'package:gitok/core/managers/window_manager.dart';
import 'package:gitok/core/managers/update_manager.dart';

/// GitOK - Git仓库管理工具
///
/// 这是应用程序的入口文件，负责初始化应用并配置基础设置。
/// 包括平台检测、窗口配置等全局设置。
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 对于热重载，`unregisterAll()` 需要被调用。
  await hotKeyManager.unregisterAll();

  // 初始化各个管理器
  await AppTrayManager().init();
  await AppWindowManager().init();
  await AppUpdateManager().init();

  runApp(const MyApp());
}
