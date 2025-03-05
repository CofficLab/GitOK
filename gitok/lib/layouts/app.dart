/// GitOK - Git仓库管理工具
///
/// 这是应用程序的入口文件，负责初始化应用并配置基础设置。
/// 包括主题、路由、依赖注入等全局配置。
library;

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:gitok/layouts/home_screen.dart';
import 'package:gitok/providers/app_provider.dart';
import 'package:provider/provider.dart';
import 'package:gitok/providers/git_provider.dart';
import 'package:gitok/theme/macos_theme.dart';

/// 应用程序的根组件
///
/// 配置应用的基础设置，包括主题、路由等
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GitProvider()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: MaterialApp(
        builder: BotToastInit(),
        navigatorObservers: [BotToastNavigatorObserver()],
        debugShowCheckedModeBanner: false,
        theme: MacOSTheme.lightTheme,
        darkTheme: MacOSTheme.darkTheme,
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          scrollbars: true, // 始终显示滚动条
          dragDevices: {
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
            PointerDeviceKind.touch,
          },
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
