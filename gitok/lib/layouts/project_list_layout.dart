import 'package:flutter/material.dart';
import 'package:gitok/widgets/project_list.dart';
import 'package:gitok/models/git_project.dart';

/// GitOK应用程序的左侧项目列表布局组件。
///
/// 提供一个固定宽度的容器，包含：
/// - 项目列表组件
/// - 右侧分割线
class ProjectListLayout extends StatelessWidget {
  /// 是否启用调试模式以突出显示布局边界
  static const bool kDebugLayout = true;

  /// 项目列表的全局键，用于访问列表状态
  final GlobalKey<ProjectListState> listKey;

  /// 当选择项目时的回调函数
  final Function(GitProject) onProjectSelected;

  const ProjectListLayout({
    super.key,
    required this.listKey,
    required this.onProjectSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
        color: kDebugLayout ? Colors.blue.withOpacity(0.1) : null,
      ),
      child: kDebugLayout
          ? Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: ProjectList(
                key: listKey,
                onProjectSelected: onProjectSelected,
              ),
            )
          : ProjectList(
              key: listKey,
              onProjectSelected: onProjectSelected,
            ),
    );
  }
}
