import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gitok/providers/git_provider.dart';
import 'package:gitok/tab_git/git_management_tab.dart';

/// GitOK应用程序的右侧项目详情布局组件。
///
/// 提供一个自适应宽度的容器，显示：
/// - 项目详情面板
/// - 当没有选中项目时显示空状态
class ProjectDetailLayout extends StatelessWidget {
  /// 是否启用调试模式以突出显示布局边界
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
        child: gitProvider.currentProject == null
            ? const Center(child: Text('请选择一个项目'))
            : GitManagementTab(project: gitProvider.currentProject!),
      ),
    );
  }
}
