/// GitOK - Git仓库管理工具
///
/// 这是应用程序的入口文件，负责初始化应用并配置基础设置。
/// 包括主题、路由、依赖注入等全局配置。

import 'package:flutter/material.dart';
import 'package:gitok/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:gitok/providers/git_provider.dart';

void main() {
  runApp(const MyApp());
}

/// 应用程序的根组件
///
/// 配置应用的基础设置，包括主题、路由等
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GitProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
          ),
        ),
        home: const Scaffold(
          body: HomeScreen(),
        ),
      ),
    );
  }
}
