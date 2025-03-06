import 'package:flutter/material.dart';
import 'package:gitok/plugins/git/models/commit_info.dart';
import 'package:gitok/plugins/git/git_provider.dart';
import 'package:gitok/plugins/git/git_service.dart';
import 'package:provider/provider.dart';

/// Git提交历史列表项组件
///
/// 在提交历史列表中展示单个提交的简要信息，包括：
/// - 提交信息
/// - 作者和时间
/// - 提交哈希值简写
class CommitListItem extends StatefulWidget {
  final CommitInfo commit;
  final bool isSelected;
  final VoidCallback onTap;

  const CommitListItem({
    super.key,
    required this.commit,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<CommitListItem> createState() => _CommitListItemState();
}

class _CommitListItemState extends State<CommitListItem> {
  final GitService _gitService = GitService();
  bool _isUnpushed = false;

  @override
  void initState() {
    super.initState();
    _checkPushStatus();
  }

  Future<void> _checkPushStatus() async {
    if (widget.commit.hash == 'current') return;
    final gitProvider = context.read<GitProvider>();
    final project = gitProvider.currentProject;
    if (project == null) return;

    final isPushed = await _gitService.isCommitPushed(project.path, widget.commit.hash);
    setState(() {
      _isUnpushed = !isPushed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: widget.isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: widget.onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: ListTile(
          title: Text(widget.commit.message),
          subtitle: Text(
            '${widget.commit.author} • ${_formatDate(widget.commit.date)}\n'
            '${widget.commit.hash.substring(0, 7)}',
          ),
          trailing: widget.commit.hash == 'current'
              ? null
              : _isUnpushed
                  ? Tooltip(
                      message: '未推送到远程',
                      child: Icon(
                        Icons.upload,
                        color: Theme.of(context).colorScheme.secondary,
                        size: 20,
                      ),
                    )
                  : null,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}
