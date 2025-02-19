import 'package:flutter/material.dart';
import 'package:gitok/models/git_project.dart';
import 'package:gitok/services/git_service.dart';
import 'package:gitok/widgets/git/commit_detail.dart';
import 'package:provider/provider.dart';
import 'package:gitok/providers/git_provider.dart';
import 'package:gitok/widgets/git/commit_history.dart';

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
  final TextEditingController _commitMessageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setDefaultCommitMessage();
  }

  @override
  void dispose() {
    _commitMessageController.dispose();
    super.dispose();
  }

  Future<void> _setDefaultCommitMessage() async {
    final gitProvider = context.read<GitProvider>();
    final project = gitProvider.currentProject;
    if (project == null) return;

    final branchName = await GitService().getCurrentBranch(project.path);
    _commitMessageController.text = 'feat($branchName): ';
    _commitMessageController.selection = TextSelection.fromPosition(
      TextPosition(offset: _commitMessageController.text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                commitMessageController:
                    gitProvider.rightPanelType == RightPanelType.commitForm ? _commitMessageController : null,
              ),
            ),
          ],
        );
      },
    );
  }
}
