/// GitOK - Git仓库管理工具
///
/// 这是应用程序的入口文件，负责初始化应用并配置基础设置。
/// 包括主题、路由、依赖注入等全局配置。
library;

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:gitok/core/layouts/home_screen.dart';
import 'package:gitok/core/theme/macos_theme.dart';
import 'package:gitok/plugins/welcome/welcome_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gitok/core/managers/tray_manager.dart';
import 'package:gitok/core/managers/window_manager.dart';
import 'package:gitok/core/managers/hotkey_manager.dart';
import 'package:tray_manager/tray_manager.dart' as tray;

/// 应用程序的根组件
///
/// 配置应用的基础设置，包括主题、路由等
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with tray.TrayListener implements WindowListener {
  String _initialRoute = '/';
  final _trayManager = AppTrayManager();
  final _windowManager = AppWindowManager();
  final _hotkeyManager = AppHotkeyManager();

  @override
  void initState() {
    super.initState();
    _windowManager.addListener(this);
    tray.trayManager.addListener(this);
    _hotkeyManager.init();
    _checkWelcomePage();
    _trayManager.init();
  }

  Future<void> _checkWelcomePage() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenWelcome = prefs.getBool('has_seen_welcome') ?? false;
    if (hasSeenWelcome) {
      setState(() {
        _initialRoute = '/home';
      });
    }
  }

  // 当窗口关闭时，隐藏而不是退出
  @override
  void onWindowClose() {
    _windowManager.hide();
  }

  @override
  void onWindowFocus() {}

  @override
  void onWindowBlur() {}

  @override
  void onWindowMaximize() {}

  @override
  void onWindowUnmaximize() {}

  @override
  void onWindowMinimize() {}

  @override
  void onWindowRestore() {}

  @override
  void onWindowMove() {}

  @override
  void onWindowResize() {}

  // 处理托盘菜单点击事件
  @override
  void onTrayMenuItemClick(tray.MenuItem menuItem) {
    _trayManager.onTrayMenuItemClick(menuItem);
  }

  // 处理托盘图标点击事件
  @override
  void onTrayIconMouseDown() {
    _trayManager.onTrayIconMouseDown();
  }

  // 处理托盘图标右键点击事件
  @override
  void onTrayIconRightMouseDown() {
    _trayManager.onTrayIconRightMouseDown();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: BotToastInit(),
      navigatorObservers: [BotToastNavigatorObserver()],
      debugShowCheckedModeBanner: false,
      theme: MacOSTheme.lightTheme.copyWith(
        scaffoldBackgroundColor: Colors.transparent, // 设置脚手架背景透明
        canvasColor: Colors.transparent, // 设置画布背景透明
      ),
      darkTheme: MacOSTheme.darkTheme.copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        canvasColor: Colors.transparent,
      ),
      initialRoute: _initialRoute,
      routes: {
        '/': (context) => const WelcomePage(),
        '/home': (context) => const HomeScreen(),
      },
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        scrollbars: true, // 始终显示滚动条
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.touch,
        },
      ),
    );
  }

  @override
  void dispose() {
    _hotkeyManager.dispose();
    _windowManager.removeListener(this);
    tray.trayManager.removeListener(this);
    super.dispose();
  }
}
