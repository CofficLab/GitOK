/// GitOK - Git仓库管理工具
///
/// 这是应用程序的入口文件，负责初始化应用并配置基础设置。
/// 包括主题、路由、依赖注入等全局配置。
library;

import 'dart:io' show Platform, exit;
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gitok/core/layouts/home_screen.dart';
import 'package:gitok/core/theme/macos_theme.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:gitok/plugins/welcome/welcome_page.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 应用程序的根组件
///
/// 配置应用的基础设置，包括主题、路由等
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WindowListener, TrayListener {
  String _initialRoute = '/';

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    trayManager.addListener(this);
    _setupGlobalHotkey();
    _setupKeyboardListener();
    _checkWelcomePage();
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

  void _setupKeyboardListener() {
    RawKeyboard.instance.addListener(_onKey);
  }

  void _onKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        windowManager.hide();
      }
    }
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
          await _bringToFront();
        },
      );

      // 注册Command+D热键
      await hotKeyManager.register(
        cmdDHotKey,
        keyDownHandler: (hotKey) async {
          if (kDebugMode) {
            print('Command+D 热键被触发');
          }
          await _bringToFront();
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

  /// 将窗口带到前台
  Future<void> _bringToFront() async {
    try {
      await windowManager.show();
      await windowManager.focus();

      BotToast.showText(text: '应用已成功回到前台');
    } catch (e) {
      if (kDebugMode) {
        print('将窗口带到前台失败: $e');
      }
    }
  }

  // 当窗口关闭时，隐藏而不是退出
  @override
  void onWindowClose() {
    windowManager.hide();
  }

  // 处理托盘菜单点击事件
  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'show_window') {
      _bringToFront();
    } else if (menuItem.key == 'exit_app') {
      // 完全退出应用程序
      exit(0);
    }
  }

  // 处理托盘图标点击事件
  @override
  void onTrayIconMouseDown() {
    // 在macOS上，点击托盘图标时显示菜单
    if (Platform.isMacOS) {
      trayManager.popUpContextMenu();
    } else {
      // 在Windows和Linux上，点击托盘图标时显示窗口
      _bringToFront();
    }
  }

  // 处理托盘图标右键点击事件
  @override
  void onTrayIconRightMouseDown() {
    // 在Windows和Linux上，右键点击托盘图标时显示菜单
    trayManager.popUpContextMenu();
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
    // 移除键盘监听器
    RawKeyboard.instance.removeListener(_onKey);
    // 注销所有热键
    hotKeyManager.unregisterAll();
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    super.dispose();
  }
}
