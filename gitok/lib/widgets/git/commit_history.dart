import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gitok/models/commit_info.dart';
import 'package:gitok/providers/git_provider.dart';
import 'package:gitok/services/git_service.dart';
import 'package:gitok/widgets/git/commit_list_item.dart';
import 'package:gitok/widgets/git/commit_detail.dart';

/// Git提交历史展示组件
///
/// 显示Git仓库的提交历史记录，包括：
/// - 提交信息
/// - 作者和时间
/// - 提交哈希值
/// - 刷新按钮
class CommitHistory extends StatefulWidget {
  /// 是否启用调试模式以突出显示布局边界
  static const bool kDebugLayout = false;

  const CommitHistory({super.key});

  @override
  State<CommitHistory> createState() => _CommitHistoryState();
}

class _CommitHistoryState extends State<CommitHistory> {
  final GitService _gitService = GitService();
  List<CommitInfo> _commits = [];
  bool _isLoading = false;
  CommitInfo? _selectedCommit;

  Future<void> _loadCommits() async {
    final project = context.read<GitProvider>().currentProject;
    if (project == null) return;

    setState(() => _isLoading = true);
    try {
      final commits = await _gitService.getCommitHistory(project.path);
      setState(() => _commits = commits);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCommits();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 当项目变化时重新加载提交历史
    final currentProject = context.watch<GitProvider>().currentProject;
    if (currentProject != null) {
      _loadCommits();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('提交历史', style: Theme.of(context).textTheme.titleMedium),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadCommits,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: _commits.length + 1, // +1 为"当前状态"项
            itemBuilder: (context, index) {
              if (index == 0) {
                // 第一项是"当前状态"
                return CommitListItem(
                  commit: CommitInfo(
                    hash: 'current',
                    message: '当前状态',
                    author: '未提交的更改',
                    date: DateTime.now(),
                  ),
                  isSelected: context.read<GitProvider>().rightPanelType == RightPanelType.commitForm,
                  onTap: () => context.read<GitProvider>().showCommitForm(),
                );
              }
              // 其他项是实际的提交历史
              final commit = _commits[index - 1];
              return CommitListItem(
                commit: commit,
                isSelected: context.read<GitProvider>().selectedCommit?.hash == commit.hash,
                onTap: () => context.read<GitProvider>().setSelectedCommit(commit),
              );
            },
          ),
        ),
      ],
    );

    if (CommitHistory.kDebugLayout) {
      content = Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.green, width: 2),
          color: Colors.green.withOpacity(0.1),
        ),
        child: content,
      );
    }

    return content;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
