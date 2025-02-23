import 'package:flutter/material.dart';
import 'package:gitok/tab_project/project_list.dart';

/// GitOK应用程序的左侧项目列表布局组件。
///
/// 提供一个固定宽度的容器，包含：
/// - 项目列表组件
/// - 右侧分割线
class ProjectListLayout extends StatelessWidget {
  /// 是否启用调试模式以突出显示布局边界
  static const bool kDebugLayout = false;

  const ProjectListLayout({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: kDebugLayout ? Colors.blue.withOpacity(0.1) : null,
      ),
      child: kDebugLayout
          ? Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: const ProjectList(),
            )
          : const ProjectList(),
    );
  }
}
