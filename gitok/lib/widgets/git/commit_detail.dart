import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gitok/models/commit_info.dart';
import 'package:gitok/providers/git_provider.dart';
import 'package:gitok/services/git_service.dart';

/// Git提交详情展示组件
///
/// 展示单个Git提交的详细信息，包括：
/// - 完整的提交信息
/// - 提交的文件变更
/// - 具体的代码差异
class CommitDetail extends StatefulWidget {
  static const bool kDebugLayout = false;

  const CommitDetail({super.key});

  @override
  State<CommitDetail> createState() => _CommitDetailState();
}

class _CommitDetailState extends State<CommitDetail> {
  final GitService _gitService = GitService();
  bool _isLoading = false;
  String _diffContent = '';

  Future<void> _loadDiff() async {
    final gitProvider = context.read<GitProvider>();
    final project = gitProvider.currentProject;
    final commit = gitProvider.selectedCommit;

    if (project == null || commit == null) return;

    setState(() => _isLoading = true);
    try {
      final diff = await _gitService.getDiff(project.path, commit.hash);
      setState(() => _diffContent = diff);
    } catch (e) {
      setState(() => _diffContent = '加载差异失败: $e 😢');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void didUpdateWidget(CommitDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当选中的提交变化时重新加载差异
    final commit = context.read<GitProvider>().selectedCommit;
    if (commit != null) {
      _loadDiff();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GitProvider>(
      builder: (context, gitProvider, _) {
        final project = gitProvider.currentProject;
        final commit = gitProvider.selectedCommit;

        Widget content;
        if (project == null || commit == null) {
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
                  commit.message,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '提交者: ${commit.author}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '时间: ${commit.date.toString()}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Hash: ${commit.hash}',
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
      },
    );
  }
}
