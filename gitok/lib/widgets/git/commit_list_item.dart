import 'package:flutter/material.dart';
import 'package:gitok/models/commit_info.dart';

/// Git提交历史列表项组件
///
/// 在提交历史列表中展示单个提交的简要信息，包括：
/// - 提交信息
/// - 作者和时间
/// - 提交哈希值简写
class CommitListItem extends StatelessWidget {
  final CommitInfo commit;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isUnpushed;

  const CommitListItem({
    super.key,
    required this.commit,
    required this.isSelected,
    required this.onTap,
    this.isUnpushed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: ListTile(
          title: Text(commit.message),
          subtitle: Text(
            '${commit.author} • ${_formatDate(commit.date)}\n'
            '${commit.hash.substring(0, 7)}',
          ),
          trailing: isUnpushed
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
