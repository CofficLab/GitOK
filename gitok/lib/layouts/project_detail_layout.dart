import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gitok/providers/git_provider.dart';
import 'package:gitok/providers/app_provider.dart';
import 'package:gitok/pages/git_page.dart';
import 'package:gitok/pages/icon_page.dart';
import 'package:gitok/pages/promo_page.dart';
import 'package:gitok/pages/api_page.dart';

/// GitOK应用程序的右侧项目详情布局组件。
///
/// 提供一个自适应宽度的容器，显示：
/// - 项目详情面板
/// - 当没有选中项目时显示空状态
/// - 当选中项目时显示Git管理标签页
/// - 自动适应窗口大小，确保良好的显示效果
class ProjectDetailLayout extends StatelessWidget {
  /// 是否启用调试模式以突出显示布局边界
  /// true: 显示绿色边框和半透明背景
  /// false: 正常显示，不显示调试信息
  static const bool kDebugLayout = false;

  const ProjectDetailLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GitProvider>(
      builder: (context, gitProvider, _) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 0),
        decoration: kDebugLayout
            ? BoxDecoration(
                border: Border.all(color: Colors.green, width: 2),
                color: Colors.green.withOpacity(0.1),
              )
            : null,
        // 根据是否选中项目显示不同的内容
        // - 未选中项目：显示提示信息
        // - 已选中项目：显示Git管理标签页
        child: gitProvider.currentProject == null
            ? const Center(child: Text('请选择一个项目'))
            : Consumer<AppProvider>(
                builder: (context, appProvider, _) {
                  final currentTabIndex = appProvider.currentTabIndex;
                  return switch (currentTabIndex) {
                    0 => GitPage(project: gitProvider.currentProject!),
                    1 => IconPage(project: gitProvider.currentProject!),
                    2 => PromoPage(project: gitProvider.currentProject!),
                    3 => ApiPage(project: gitProvider.currentProject!),
                    _ => const Center(child: Text('未知的标签页')),
                  };
                },
              ),
      ),
    );
  }
}
