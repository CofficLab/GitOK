import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gitok/models/commit_info.dart';
import 'package:gitok/providers/git_provider.dart';
import 'package:gitok/widgets/tab_git/commit_list_item.dart';

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
  bool _isLoading = false;

  Future<void> _loadCommits() async {
    final project = context.read<GitProvider>().currentProject;
    if (project == null) return;

    setState(() => _isLoading = true);
    try {
      await context.read<GitProvider>().loadCommits();
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
    final currentProject = context.read<GitProvider>().currentProject;
    if (currentProject != null) {
      _loadCommits();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('提交历史', style: Theme.of(context).textTheme.titleMedium),
              // 刷新按钮：点击时重新加载提交历史
              // 当仓库有新的提交时，用户可以通过此按钮手动更新列表
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadCommits,
                tooltip: '刷新提交历史',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Consumer<GitProvider>(
              builder: (context, gitProvider, _) {
                final commits = gitProvider.commits;
                return ListView.builder(
                  itemCount: commits.length + 1,
                  itemBuilder: (context, index) {
                    // 在列表顶部显示当前状态项
                    // 点击后显示提交表单，用于创建新的提交
                    if (index == 0) {
                      return CommitListItem(
                        commit: CommitInfo(
                          hash: 'current',
                          message: '当前状态',
                          author: '未提交的更改',
                          date: DateTime.now(),
                        ),
                        isSelected: gitProvider.rightPanelType == RightPanelType.commitForm,
                        onTap: () => gitProvider.showCommitForm(),
                      );
                    }
                    // 显示历史提交记录
                    // 点击后在右侧面板显示该提交的详细信息
                    final commit = commits[index - 1];
                    return CommitListItem(
                      commit: commit,
                      isSelected: gitProvider.rightPanelType == RightPanelType.commitDetail &&
                          gitProvider.selectedCommit?.hash == commit.hash,
                      onTap: () => gitProvider.setSelectedCommit(commit),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
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
}
