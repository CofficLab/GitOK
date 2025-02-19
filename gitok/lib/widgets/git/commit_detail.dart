import 'package:flutter/material.dart';
import 'package:gitok/models/commit_info.dart';

/// Git提交详情展示组件
///
/// 展示单个Git提交的详细信息，包括：
/// - 完整的提交信息
/// - 提交的文件变更
/// - 具体的代码差异
class CommitDetail extends StatefulWidget {
  static const bool kDebugLayout = false;

  final String projectPath;
  final CommitInfo? commit;

  const CommitDetail({
    super.key,
    required this.projectPath,
    this.commit,
  });

  @override
  State<CommitDetail> createState() => _CommitDetailState();
}

class _CommitDetailState extends State<CommitDetail> {
  bool _isLoading = false;
  String _diffContent = '';

  @override
  void didUpdateWidget(CommitDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.commit?.hash != widget.commit?.hash) {
      _loadDiff();
    }
  }

  Future<void> _loadDiff() async {
    if (widget.commit == null) return;

    setState(() => _isLoading = true);
    try {
      // TODO: 从 GitService 获取差异信息
      await Future.delayed(const Duration(seconds: 1)); // 模拟加载
      setState(() => _diffContent = '// TODO: 显示具体的代码差异');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (widget.commit == null) {
      content = const Center(
        child: Text('👈 请选择一个提交查看详情'),
      );
    } else if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else {
      content = SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.commit!.message,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '提交者: ${widget.commit!.author}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              '时间: ${widget.commit!.date.toString()}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Hash: ${widget.commit!.hash}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Divider(height: 32),
            Text(
              '变更内容:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_diffContent),
            ),
          ],
        ),
      );
    }

    if (CommitDetail.kDebugLayout) {
      content = Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.purple, width: 2),
          color: Colors.purple.withOpacity(0.1),
        ),
        child: content,
      );
    }

    return content;
  }
}
