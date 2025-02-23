import 'package:flutter/material.dart';
import 'package:gitok/models/git_project.dart';
import 'package:gitok/services/git_service.dart';
import 'package:gitok/tab_git/commit_detail.dart';
import 'package:provider/provider.dart';
import 'package:gitok/providers/git_provider.dart';
import 'package:gitok/tab_git/commit_history.dart';
import 'dart:io';

/// Git提交管理标签页组件
class GitManagementTab extends StatefulWidget {
  /// 是否启用调试模式以突出显示布局边界
  static const bool kDebugLayout = false;

  final GitProject project;

  const GitManagementTab({
    super.key,
    required this.project,
  });

  @override
  State<GitManagementTab> createState() => _GitManagementTabState();
}

class _GitManagementTabState extends State<GitManagementTab> {
  final GitService _gitService = GitService();
  bool _isValidGitRepo = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _validateProject();
  }

  Future<void> _validateProject() async {
    if (!Directory(widget.project.path).existsSync()) {
      setState(() {
        _errorMessage = '项目文件夹不存在';
        _isValidGitRepo = false;
      });
      return;
    }

    try {
      final isGitRepo = await _gitService.isGitRepository(widget.project.path);
      setState(() {
        _isValidGitRepo = isGitRepo;
        _errorMessage = isGitRepo ? null : '该文件夹不是有效的Git仓库';
      });
    } catch (e) {
      setState(() {
        _errorMessage = '验证Git仓库时出错：${e.toString()}';
        _isValidGitRepo = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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

    return Consumer<GitProvider>(
      builder: (context, gitProvider, _) {
        return Row(
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
        );
      },
    );
  }
}
