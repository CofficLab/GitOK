/// GitOK - Git仓库管理工具
///
/// 这是应用程序的入口文件，负责初始化应用并配置基础设置。
/// 包括主题、路由、依赖注入等全局配置。
library;

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gitok/core/layouts/home_screen.dart';
import 'package:gitok/core/providers/app_provider.dart';
import 'package:provider/provider.dart';
import 'package:gitok/plugins/git/git_provider.dart';
import 'package:gitok/core/theme/macos_theme.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:gitok/core/pages/welcome_page.dart';
import 'package:tray_manager/tray_manager.dart';

/// 应用程序的根组件
///
/// 配置应用的基础设置，包括主题、路由等
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WindowListener, TrayListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    trayManager.addListener(this);
    _setupGlobalHotkey();
    _setupKeyboardListener();
  }

  void _setupKeyboardListener() {
    RawKeyboard.instance.addListener((RawKeyEvent event) {
      if (event is RawKeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          windowManager.hide();
        }
      }
    });
  }

  @override
  void dispose() {
    RawKeyboard.instance.removeListener(_onKey);
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    super.dispose();
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
    final hotKey = HotKey(
      key: LogicalKeyboardKey.digit1, // 使用数字键 1
      modifiers: [HotKeyModifier.alt], // 配合 Alt 键使用
      scope: HotKeyScope.system,
    );

    try {
      await hotKeyManager.register(
        hotKey,
        keyDownHandler: (hotKey) async {
          await _bringToFront();
        },
      );

      BotToast.showText(text: '已注册全局热键：Alt + 1 可将应用带到前台');
    } catch (e) {
      BotToast.showText(text: '注册全局热键失败: $e');
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

  // 处理托盘图标双击事件
  @override
  void onTrayDoubleClick() {
    _bringToFront();
  }

  // 当窗口关闭时，隐藏而不是退出
  @override
  void onWindowClose() {
    windowManager.hide();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: MaterialApp(
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
        initialRoute: '/',
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
      ),
    );
  }
}
