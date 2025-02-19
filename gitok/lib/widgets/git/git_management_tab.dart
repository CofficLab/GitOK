import 'package:flutter/material.dart';
import 'package:gitok/models/git_project.dart';
import 'package:gitok/services/git_service.dart';
import 'package:gitok/widgets/error_snack_bar.dart';
import 'package:gitok/widgets/git/components/branch_switcher.dart';
import 'package:gitok/widgets/git/git_action_buttons.dart';
import 'package:gitok/widgets/git/commit_section.dart';

/// A tab that provides Git management functionality for a project.
///
/// This widget allows users to:
/// - View and switch between branches
/// - Pull and push changes
/// - Commit local changes
class GitManagementTab extends StatefulWidget {
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('当前分支: $_currentBranch', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          BranchSwitcher(
            currentBranch: _currentBranch,
            branches: _branches,
            onBranchChanged: (value) async {
              if (value != null) {
                try {
                  await _gitService.checkout(widget.project.path, value);
                  await _loadGitInfo();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    ErrorSnackBar(message: e.toString()),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 16),
          GitActionButtons(
            onPull: () async {
              try {
                await _gitService.pull(widget.project.path);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('拉取成功')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  ErrorSnackBar(message: e.toString()),
                );
              }
            },
            onPush: () async {
              try {
                await _gitService.push(widget.project.path);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('推送成功')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  ErrorSnackBar(message: e.toString()),
                );
              }
            },
          ),
          const SizedBox(height: 16),
          CommitSection(
            controller: _commitMessageController,
            onCommit: () async {
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
            },
          ),
        ],
      ),
    );
  }
}
