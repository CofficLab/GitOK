import 'package:flutter/material.dart';
import 'package:gitok/models/git_project.dart';
import 'package:gitok/services/git_service.dart';
import 'package:gitok/widgets/error_snack_bar.dart';
import 'package:gitok/widgets/git/commit_section.dart';
import 'package:gitok/widgets/git/commit_history.dart';
import 'package:gitok/widgets/git/commit_detail.dart';
import 'package:provider/provider.dart';
import 'package:gitok/providers/git_provider.dart';

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
  String _currentBranch = '';
  List<String> _branches = [];
  final TextEditingController _commitMessageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGitInfo();
    _setDefaultCommitMessage();
  }

  Future<void> _loadGitInfo() async {
    try {
      final currentBranch = await _gitService.getCurrentBranch(widget.project.path);
      final branches = await _gitService.getBranches(widget.project.path);
      setState(() {
        _currentBranch = currentBranch;
        _branches = branches;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        ErrorSnackBar(message: e.toString()),
      );
    }
  }

  Future<void> _setDefaultCommitMessage() async {
    final gitProvider = context.read<GitProvider>();
    final project = gitProvider.currentProject;
    if (project == null) return;

    // 获取当前分支名
    final branchName = await GitService().getCurrentBranch(project.path);

    // 设置默认提交信息
    _commitMessageController.text = 'feat($branchName): ';

    // 将光标移动到末尾
    _commitMessageController.selection = TextSelection.fromPosition(
      TextPosition(offset: _commitMessageController.text.length),
    );
  }

  @override
  void dispose() {
    _commitMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Row(
      children: [
        // 左侧栏：提交历史（包含当前状态）
        const Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: CommitHistory(),
          ),
        ),
        // 中间分割线
        const VerticalDivider(width: 1),
        // 右侧栏：根据状态显示提交表单或提交详情
        Expanded(
          flex: 1,
          child: Consumer<GitProvider>(
            builder: (context, gitProvider, _) {
              return CommitDetail(
                isCurrentChanges: gitProvider.rightPanelType == RightPanelType.commitForm,
                commitMessageController:
                    gitProvider.rightPanelType == RightPanelType.commitForm ? _commitMessageController : null,
                onCommit: gitProvider.rightPanelType == RightPanelType.commitForm
                    ? () async {
                        if (_commitMessageController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('请输入提交信息')),
                          );
                          return;
                        }

                        try {
                          await _gitService.commit(
                            widget.project.path,
                            _commitMessageController.text,
                          );
                          _commitMessageController.clear();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('提交成功')),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            ErrorSnackBar(message: e.toString()),
                          );
                        }
                      }
                    : null,
              );
            },
          ),
        ),
      ],
    );

    if (GitManagementTab.kDebugLayout) {
      content = Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orange, width: 2),
          color: Colors.orange.withOpacity(0.1),
        ),
        child: content,
      );
    }

    return content;
  }
}
