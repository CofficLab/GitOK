import 'package:flutter/material.dart';
import 'package:gitok/widgets/project_detail_panel.dart';
import 'package:gitok/models/git_project.dart';

/// GitOK应用程序的右侧项目详情布局组件。
///
/// 提供一个自适应宽度的容器，显示：
/// - 项目详情面板
/// - 当没有选中项目时显示空状态
class ProjectDetailLayout extends StatelessWidget {
  /// 是否启用调试模式以突出显示布局边界
  static const bool kDebugLayout = true;

  /// 当前选中的项目，可能为null（表示未选中任何项目）
  final GitProject? project;

  const ProjectDetailLayout({
    super.key,
    required this.project,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: kDebugLayout
            ? BoxDecoration(
                border: Border.all(color: Colors.green, width: 2),
                color: Colors.green.withOpacity(0.1),
              )
            : null,
        child: ProjectDetailPanel(project: project),
      ),
    );
  }
}
