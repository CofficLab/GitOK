import 'package:flutter/material.dart';
import 'package:gitok/layouts/home_app_bar.dart';
import 'package:gitok/layouts/project_detail_layout.dart';
import 'package:gitok/layouts/sidebar.dart';

/// GitOK应用程序的主屏幕。
/// 提供一个分屏界面，左侧是项目列表，右侧是项目详情。
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 侧边栏
          Container(
            width: 250,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1.0,
                ),
              ),
            ),
            child: const AppDrawer(),
          ),
          // 主内容区
          const Expanded(
            child: Scaffold(
              appBar: HomeAppBar(),
              body: ProjectDetailLayout(),
            ),
          ),
        ],
      ),
    );
  }
}
