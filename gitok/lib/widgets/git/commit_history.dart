import 'package:flutter/material.dart';
import 'package:gitok/models/commit_info.dart';
import 'package:gitok/widgets/git/commit_detail.dart';
import 'package:gitok/widgets/git/commit_list_item.dart';

/// Git提交历史展示组件
///
/// 显示Git仓库的提交历史记录，包括：
/// - 提交信息
/// - 作者和时间
/// - 提交哈希值
/// - 刷新按钮
class CommitHistory extends StatefulWidget {
  /// 是否启用调试模式以突出显示布局边界
  static const bool kDebugLayout = true;

  final String projectPath;
  final Future<List<CommitInfo>> Function(String path) onLoadCommits;

  const CommitHistory({
    super.key,
    required this.projectPath,
    required this.onLoadCommits,
  });

  @override
  State<CommitHistory> createState() => _CommitHistoryState();
}

class _CommitHistoryState extends State<CommitHistory> {
  List<CommitInfo> _commits = [];
  bool _isLoading = false;
  CommitInfo? _selectedCommit;

  @override
  void initState() {
    super.initState();
    _loadCommits();
  }

  Future<void> _loadCommits() async {
    setState(() => _isLoading = true);
    try {
      final commits = await widget.onLoadCommits(widget.projectPath);
      setState(() => _commits = commits);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    Widget content = Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
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
                  itemCount: _commits.length,
                  itemBuilder: (context, index) {
                    final commit = _commits[index];
                    return CommitListItem(
                      commit: commit,
                      isSelected: _selectedCommit?.hash == commit.hash,
                      onTap: () => setState(() => _selectedCommit = commit),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(),
        Expanded(
          flex: 3,
          child: CommitDetail(
            projectPath: widget.projectPath,
            commit: _selectedCommit,
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
