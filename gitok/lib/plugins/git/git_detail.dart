import 'package:flutter/material.dart';
import 'package:gitok/plugins/git/git_bar.dart';
import 'package:provider/provider.dart';
import 'package:gitok/plugins/git/git_provider.dart';
import 'package:gitok/plugins/git/commit_history.dart';
import 'package:gitok/plugins/git/commit_detail.dart';
import 'dart:io';
import 'package:gitok/plugins/git/git_service.dart';

/// Git项目详情组件
///
/// 负责展示Git项目的主要内容，包括：
/// - 验证Git仓库的有效性
/// - 显示提交历史列表
/// - 显示提交详情或当前更改
class GitDetail extends StatefulWidget {
  const GitDetail({super.key});

  @override
  State<GitDetail> createState() => _GitDetailState();
}

class _GitDetailState extends State<GitDetail> {
  final GitService _gitService = GitService();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _validateProject();
  }

  Future<void> _validateProject() async {
    final gitProvider = Provider.of<GitProvider>(context, listen: false);
    final project = gitProvider.currentProject;

    if (project == null) return;

    if (!Directory(project.path).existsSync()) {
      setState(() {
        _errorMessage = '项目文件夹不存在';
      });
      return;
    }

    try {
      final isGitRepo = await _gitService.isGitRepository(project.path);
      setState(() {
        _errorMessage = isGitRepo ? null : '该文件夹不是有效的Git仓库';
      });
    } catch (e) {
      setState(() {
        _errorMessage = '验证Git仓库时出错：${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GitProvider>(
      builder: (context, gitProvider, _) {
        if (gitProvider.currentProject == null) {
          return const Center(child: Text('请选择一个项目'));
        }

        if (_errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // 使用现有的操作栏
            const GitBar(),
            // 主要内容区
            Expanded(
              child: Row(
                children: [
                  // 左侧提交历史列表
                  const SizedBox(
                    width: 300,
                    child: CommitHistory(),
                  ),
                  // 右侧提交详情
                  Expanded(
                    child: CommitDetail(
                      isCurrentChanges: gitProvider.rightPanelType == RightPanelType.commitForm,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
