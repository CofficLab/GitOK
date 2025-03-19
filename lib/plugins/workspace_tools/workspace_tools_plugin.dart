import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gitok/core/contract/plugin_protocol.dart';
import 'package:gitok/utils/logger.dart';

/// 工作区工具插件
///
/// 提供与工作区相关的工具，包括：
/// 1. 在 Finder 中打开工作区
/// 2. 复制工作区路径
/// 3. 其他工作区相关操作
class WorkspaceToolsPlugin extends Plugin {
  static const String _tag = 'WorkspaceToolsPlugin';

  @override
  String get id => 'workspace_tools';

  @override
  String get name => '工作区工具';

  @override
  String get author => 'CofficLab';

  @override
  String get version => '1.0.0';

  @override
  String get description => '提供工作区相关的快捷操作';

  @override
  IconData get icon => Icons.folder_open;

  @override
  bool get enabled => true;

  @override
  Future<void> initialize() async {
    Logger.info(_tag, '工作区工具插件初始化');
  }

  @override
  Future<List<PluginAction>> onQuery(String keyword, [PluginContext context = const PluginContext()]) async {
    Logger.info(_tag, '收到查询: $keyword, 工作区: ${context.workspace}');

    // 如果没有工作区，返回空列表
    if (!context.hasWorkspace) {
      Logger.info(_tag, '没有工作区信息，跳过');
      return [];
    }

    final actions = <PluginAction>[];
    final workspace = context.workspace!;
    Logger.info(_tag, '准备创建工作区动作，工作区路径: $workspace');

    // 如果关键词为空，或者包含"工作区"、"workspace"等关键词，添加所有动作
    if (keyword.isEmpty ||
        keyword.contains('工作区') ||
        keyword.toLowerCase().contains('workspace') ||
        keyword.toLowerCase().contains('finder')) {
      actions.add(
        PluginAction(
          id: '$id:open_in_finder',
          title: '在 Finder 中打开工作区',
          subtitle: workspace,
          icon: const Icon(Icons.folder_open),
          score: 100,
        ),
      );
      Logger.info(_tag, '已添加打开工作区动作');
    }

    return actions;
  }

  @override
  Future<void> onAction(String actionId, BuildContext buildContext,
      [PluginContext pluginContext = const PluginContext()]) async {
    Logger.info(_tag, '收到动作: $actionId');

    if (!pluginContext.hasWorkspace) {
      Logger.error(_tag, '没有工作区信息，无法执行动作');
      return;
    }

    final workspace = pluginContext.workspace!;
    Logger.info(_tag, '准备处理动作: $actionId, 工作区: $workspace');

    switch (actionId) {
      case 'workspace_tools:open_in_finder':
        try {
          if (Platform.isMacOS) {
            Logger.info(_tag, '正在执行 open 命令: $workspace');
            final result = await Process.run('open', [workspace]);
            if (result.exitCode != 0) {
              Logger.error(_tag, '打开 Finder 失败: ${result.stderr}');
            } else {
              Logger.info(_tag, '成功在 Finder 中打开工作区');
            }
          }
        } catch (e) {
          Logger.error(_tag, '打开 Finder 时发生错误', e);
        }
        break;
    }
  }

  @override
  Future<void> dispose() async {
    Logger.info(_tag, '工作区工具插件销毁');
  }
}
