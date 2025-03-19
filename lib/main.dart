/// GitOK - 应用程序入口
///
/// 这个文件是应用程序的入口点，主要负责：
/// 1. 初始化各个管理器（Manager）
/// 2. 作为中介者协调各个管理器之间的通信
/// 3. 配置应用的基础设置，包括主题、路由等
///
/// 设计模式：中介者模式（Mediator Pattern）
/// - 各个管理器（WindowManager、TrayManager、HotkeyManager等）之间不直接通信
/// - 所有管理器之间的交互都通过 MyApp 类来中转
/// - 每个管理器只需要关注自己的职责，不需要知道其他管理器的存在
///
/// 事件流转示例：
/// 1. 用户按下快捷键：
///    HotkeyManager(触发) -> MyApp(中转) -> WindowManager(执行)
/// 2. 用户点击托盘：
///    TrayManager(触发) -> MyApp(中转) -> WindowManager(执行)
/// 3. 窗口状态改变：
///    WindowManager(触发) -> MyApp(中转) -> TrayManager(更新状态)
library;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:gitok/plugins/config/config_plugin.dart';
import 'package:gitok/plugins/workspace_tools/workspace_tools_plugin.dart';
import 'package:gitok/plugins/git_commit/git_commit_plugin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gitok/core/views/home_screen.dart';
import 'package:gitok/core/theme/macos_theme.dart';
import 'package:gitok/core/managers/tray_manager.dart';
import 'package:gitok/core/managers/window_manager.dart';
import 'package:gitok/core/managers/hotkey_manager.dart';
import 'package:gitok/core/managers/update_manager.dart';
import 'package:gitok/core/managers/plugin_manager.dart';
import 'package:tray_manager/tray_manager.dart' as tray;
import 'package:hotkey_manager/hotkey_manager.dart' as hotkey;
import 'plugins/app_launcher/app_launcher_plugin.dart';
import 'package:gitok/core/providers/companion_provider.dart';
import 'package:gitok/core/channels/channels.dart';
import 'package:provider/provider.dart';
import 'package:gitok/core/providers/window_state_provider.dart';

/// 应用程序的根组件
///
/// 作为中介者，负责：
/// 1. 初始化和管理所有的 Manager 实例
/// 2. 处理各个 Manager 之间的事件传递
/// 3. 配置应用的主题、路由等基础设置
///
/// 中介者职责：
/// - 接收各个 Manager 的事件通知
/// - 协调 Manager 之间的交互
/// - 维护 Manager 之间的依赖关系
/// - 降低 Manager 之间的耦合度
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with tray.TrayListener implements WindowListener {
  String _initialRoute = '/home';
  final _trayManager = AppTrayManager();
  final _windowManager = AppWindowManager();
  final _hotkeyManager = AppHotkeyManager();
  final _pluginManager = AppPluginManager();
  final _windowStateProvider = WindowStateProvider();

  @override
  void initState() {
    super.initState();
    _windowManager.addListener(this);
    tray.trayManager.addListener(this);

    // 设置窗口管理器的事件回调
    _windowManager.onWindowHidden = () {
      // 当窗口隐藏时，更新状态
      _windowStateProvider.setVisibility(false);
      _trayManager.updateTrayIcon(isWindowVisible: false);
    };

    _windowManager.onWindowShown = () {
      // 当窗口显示时，更新状态
      _windowStateProvider.setVisibility(true);
      _trayManager.updateTrayIcon(isWindowVisible: true);
    };

    _windowManager.onQuitRequested = () {
      // 退出前的清理工作
      _hotkeyManager.dispose();
      _pluginManager.dispose();
      _trayManager.dispose();
    };

    // 初始化快捷键管理器，并设置事件处理
    _hotkeyManager.init();
    _hotkeyManager.onShowWindowRequested = () {
      _windowManager.show();
      _windowManager.focus();
      BotToast.showText(text: '应用已成功回到前台');
    };

    _hotkeyManager.onHideWindowRequested = () {
      _windowManager.hide();
    };

    _checkWelcomePage();

    // 初始化托盘，并设置托盘事件处理
    _trayManager.init();
    _trayManager.onShowWindowRequested = () {
      _windowManager.show();
      _windowManager.focus();
      BotToast.showText(text: '应用已成功回到前台');
    };

    _trayManager.onQuitRequested = () {
      _windowManager.quit();
    };

    // 立即初始化插件
    _initializePlugins().then((_) {
      debugPrint('🎉 插件初始化完成！');
    }).catchError((error) {
      debugPrint('❌ 插件初始化失败：$error');
    });
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

  Future<void> _initializePlugins() async {
    // 注册应用启动器插件
    await _pluginManager.registerPlugin(AppLauncherPlugin());
    await _pluginManager.registerPlugin(ConfigPlugin());
    await _pluginManager.registerPlugin(WorkspaceToolsPlugin());
    await _pluginManager.registerPlugin(GitCommitPlugin());
  }

  // 当窗口关闭时，隐藏而不是退出
  @override
  void onWindowClose() {
    _windowManager.hide();
  }

  @override
  void onWindowFocus() {
    _windowStateProvider.setFocus(true);
  }

  @override
  void onWindowBlur() {
    _windowStateProvider.setFocus(false);
  }

  @override
  void onWindowMaximize() {
    _windowStateProvider.setMaximized(true);
  }

  @override
  void onWindowUnmaximize() {
    _windowStateProvider.setMaximized(false);
  }

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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _windowStateProvider),
      ],
      child: MaterialApp(
        builder: BotToastInit(),
        navigatorObservers: [BotToastNavigatorObserver()],
        debugShowCheckedModeBanner: false,
        theme: MacOSTheme.lightTheme.copyWith(
          scaffoldBackgroundColor: Colors.transparent,
          canvasColor: Colors.transparent,
        ),
        darkTheme: MacOSTheme.darkTheme.copyWith(
          scaffoldBackgroundColor: Colors.transparent,
          canvasColor: Colors.transparent,
        ),
        initialRoute: _initialRoute,
        routes: {
          '/home': (context) => HomeScreen(pluginManager: _pluginManager),
        },
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          scrollbars: true,
          dragDevices: {
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
            PointerDeviceKind.touch,
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hotkeyManager.dispose();
    _windowManager.removeListener(this);
    tray.trayManager.removeListener(this);
    _pluginManager.dispose();
    super.dispose();
  }
}

void main() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化日志通道
  LoggerChannel.instance;

  // 初始化伙伴提供者
  await CompanionProvider().initialize();

  // 为了支持热重载，每次启动时都注销所有热键
  await hotkey.hotKeyManager.unregisterAll();

  // 初始化系统托盘
  await AppTrayManager().init();

  // 初始化应用更新管理器
  await AppUpdateManager().init();

  await AppWindowManager().init();

  runApp(const MyApp());
}
