import 'package:flutter/material.dart';
import 'package:gitok/models/commit_info.dart';

/// 提交信息面板组件
class CommitInfoPanel extends StatelessWidget {
  final CommitInfo commit;

  const CommitInfoPanel({super.key, required this.commit});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(commit.message, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text('作者: ${commit.author}', style: Theme.of(context).textTheme.bodyMedium),
        Text('时间: ${_formatDate(commit.date)}', style: Theme.of(context).textTheme.bodyMedium),
        Text('Hash: ${commit.hash}', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
