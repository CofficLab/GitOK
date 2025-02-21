import 'package:flutter/material.dart';
import 'package:gitok/models/git_project.dart';
import 'package:gitok/widgets/git/git_management_tab.dart';
import 'package:gitok/widgets/icon/icon_editor_tab.dart';
import 'package:gitok/widgets/promo/promo_editor_tab.dart';
import 'package:gitok/widgets/api/api_editor_tab.dart';

class ProjectDetailPanel extends StatelessWidget {
  final GitProject? project;

  const ProjectDetailPanel({
    super.key,
    this.project,
  });

  @override
  Widget build(BuildContext context) {
    if (project == null) {
      return const Center(
        child: Text('选择一个项目以查看详情'),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Git管理'),
              Tab(text: 'APP图标'),
              Tab(text: '宣传图'),
              Tab(text: 'API测试'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                GitManagementTab(project: project!),
                IconEditorTab(project: project!),
                PromoEditorTab(project: project!),
                ApiEditorTab(project: project!),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
