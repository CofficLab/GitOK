import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gitok/core/contract/plugin_protocol.dart';
import 'package:gitok/plugins/git/git_provider.dart';
import 'package:gitok/plugins/git/sidebar.dart';
import 'package:gitok/plugins/git/git_detail.dart';

/// Git管理功能插件
///
/// 提供完整的Git项目管理功能：
/// - 左侧项目列表
/// - 右侧项目详情和操作面板
/// - 自包含的状态管理
class GitPlugin implements PluginProtocol {
  @override
  String get name => 'Git管理';

  @override
  IconData get icon => Icons.source_rounded;

  @override
  String get description => 'Git仓库管理与版本控制';

  @override
  bool get enabled => true;

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
            child: GitDetail(),
          ),
        ],
      ),
    );
  }
}
