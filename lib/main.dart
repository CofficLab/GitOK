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

/// 应用程序的根组件
///
/// 配置应用的基础设置，包括主题、路由等
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

  @override
  void initState() {
    super.initState();
    _windowManager.addListener(this);
    tray.trayManager.addListener(this);
    _hotkeyManager.init();
    _checkWelcomePage();
    _trayManager.init();
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
        '/home': (context) => HomeScreen(pluginManager: _pluginManager),
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
