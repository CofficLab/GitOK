import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gitok/providers/git_provider.dart';
import 'package:gitok/layouts/sidebar.dart';
import 'package:gitok/layouts/project_detail_layout.dart';

/// Git管理功能组件
///
/// 提供完整的Git项目管理功能：
/// - 左侧项目列表
/// - 右侧项目详情和操作面板
class GitFeature extends StatelessWidget {
  const GitFeature({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GitProvider(),
      child: const Row(
        children: [
          // 左侧项目列表
          SizedBox(
            width: 260,
            child: AppDrawer(),
          ),
          // 分隔线
          VerticalDivider(width: 1),
          // 右侧项目详情
          Expanded(
            child: ProjectDetailLayout(),
          ),
        ],
      ),
    );
  }
}
