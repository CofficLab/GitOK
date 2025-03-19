import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gitok/core/contract/plugin_protocol.dart';
import 'package:gitok/utils/logger.dart';
import 'package:gitok/utils/path_utils.dart';
import 'package:git/git.dart';

/// Git Commit 插件
///
/// 提供 Git 相关的快捷操作，包括：
/// 1. 检测当前工作区是否为 Git 仓库
/// 2. 自动生成 commit 信息
/// 3. 执行 git commit 操作
class GitCommitPlugin extends Plugin {
  static const String _tag = 'GitCommitPlugin';
  GitDir? _gitDir;

  @override
  String get id => 'git_commit';

  @override
  String get name => 'Git Commit';

  @override
  String get author => 'CofficLab';

  @override
  String get version => '1.0.0';

  @override
  String get description => '提供 Git commit 相关的快捷操作';

  @override
  IconData get icon => Icons.commit;

  @override
  bool get enabled => true;

  @override
  Future<void> initialize() async {
    Logger.info(_tag, 'Git Commit 插件初始化');
  }

  /// 检查目录是否为 Git 仓库并初始化 GitDir
  Future<bool> _initGitDir(String path) async {
    try {
      final normalizedPath = PathUtils.normalizeUri(path);
      Logger.info(_tag, '规范化后的路径: $normalizedPath');

      final isGit = await GitDir.isGitDir(normalizedPath);
      if (isGit) {
        _gitDir = await GitDir.fromExisting(normalizedPath);
        return true;
      }
      return false;
    } catch (e) {
      Logger.error(_tag, '检查 Git 仓库时发生错误', e);
      return false;
    }
  }

  /// 获取 Git 状态
  Future<bool> _hasChangesToCommit(GitDir gitDir) async {
    try {
      final status = await gitDir.runCommand(['status', '--porcelain']);
      return status.stdout.toString().trim().isNotEmpty;
    } catch (e) {
      Logger.error(_tag, '获取 Git 状态时发生错误', e);
      return false;
    }
  }

  /// 生成 commit 信息
  Future<String> _generateCommitMessage(GitDir gitDir) async {
    try {
      // 获取修改的文件列表
      final diffNameOnly = await gitDir.runCommand(['diff', '--name-only', '--cached']);
      final files = diffNameOnly.stdout.toString().trim().split('\n');

      // 获取具体的修改内容
      final diffStat = await gitDir.runCommand(['diff', '--cached', '--stat']);
      final details = diffStat.stdout.toString().trim();

      // 生成简单的 commit 信息
      final message = '🤖 Auto Commit\n\n'
          '修改的文件:\n${files.map((f) => "- $f").join('\n')}\n\n'
          '修改统计:\n$details';

      return message;
    } catch (e) {
      Logger.error(_tag, '生成 commit 信息时发生错误', e);
      return '🤖 Auto Commit';
    }
  }

  @override
  Future<List<PluginAction>> onQuery(String keyword, [PluginContext context = const PluginContext()]) async {
    Logger.info(_tag, '收到查询: $keyword, 工作区: ${context.workspace}');

    // 如果没有工作区，返回空列表
    if (!context.hasWorkspace) {
      Logger.info(_tag, '没有工作区信息，跳过');
      return [];
    }

    final workspace = context.workspace!;

    // 检查是否为 Git 仓库
    if (!await _initGitDir(workspace)) {
      Logger.info(_tag, '不是 Git 仓库，跳过');
      return [];
    }

    // 检查是否有需要提交的更改
    if (!await _hasChangesToCommit(_gitDir!)) {
      Logger.info(_tag, '没有需要提交的更改，跳过');
      return [];
    }

    final actions = <PluginAction>[];

    // 如果关键词为空，或者包含"git"、"commit"等关键词，添加动作
    if (keyword.isEmpty || keyword.toLowerCase().contains('git') || keyword.toLowerCase().contains('commit')) {
      actions.add(
        PluginAction(
          id: '$id:auto_commit',
          title: '自动生成 Commit 信息并提交',
          subtitle: '使用 AI 生成 commit 信息',
          icon: const Icon(Icons.commit),
          score: 100,
        ),
      );
      Logger.info(_tag, '已添加自动提交动作');
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

    if (!await _initGitDir(workspace)) {
      Logger.error(_tag, '不是 Git 仓库，无法执行操作');
      return;
    }

    switch (actionId) {
      case 'git_commit:auto_commit':
        try {
          // 先执行 git add .
          await _gitDir!.runCommand(['add', '.']);

          // 生成 commit 信息
          final commitMessage = await _generateCommitMessage(_gitDir!);

          // 执行 commit
          final result = await _gitDir!.runCommand(['commit', '-m', commitMessage]);

          if (result.exitCode == 0) {
            Logger.info(_tag, '成功提交更改');
          } else {
            Logger.error(_tag, 'git commit 失败: ${result.stderr}');
          }
        } catch (e) {
          Logger.error(_tag, '执行 git commit 时发生错误', e);
        }
        break;
    }
  }

  @override
  Future<void> dispose() async {
    Logger.info(_tag, 'Git Commit 插件销毁');
    _gitDir = null;
  }
}
