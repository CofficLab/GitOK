import 'package:flutter/material.dart';
import 'package:gitok/models/file_status.dart';
import 'package:provider/provider.dart';
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
  Map<String, String> _fileDiffs = {}; // 存储每个文件的差异内容
  List<FileStatus> _changedFiles = [];
  String? _selectedFilePath; // 当前选中的文件路径

  Future<void> _loadCommitDetails() async {
    final gitProvider = context.read<GitProvider>();
    final project = gitProvider.currentProject;
    final commit = gitProvider.selectedCommit;

    if (project == null || commit == null) return;

    setState(() => _isLoading = true);
    try {
      _changedFiles = await _gitService.getCommitFiles(project.path, commit.hash);
      // 重置选中的文件
      _selectedFilePath = _changedFiles.isNotEmpty ? _changedFiles[0].path : null;
      // 加载第一个文件的差异
      if (_selectedFilePath != null) {
        await _loadFileDiff(_selectedFilePath!);
      }
    } catch (e) {
      setState(() {
        _changedFiles = [];
        _selectedFilePath = null;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFileDiff(String filePath) async {
    final gitProvider = context.read<GitProvider>();
    final project = gitProvider.currentProject;
    final commit = gitProvider.selectedCommit;

    if (project == null || commit == null) return;

    try {
      final diff = await _gitService.getFileDiff(project.path, commit.hash, filePath);
      setState(() => _fileDiffs[filePath] = diff);
    } catch (e) {
      setState(() => _fileDiffs[filePath] = '加载差异失败: $e');
    }
  }

  @override
  void didUpdateWidget(CommitDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadCommitDetails();
  }

  @override
  void initState() {
    super.initState();
    _loadCommitDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Consumer<GitProvider>(
                    builder: (context, gitProvider, _) {
                      final commit = gitProvider.selectedCommit;
                      if (commit == null) {
                        return const Text('👈 请选择一个提交查看详情');
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            commit.message,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '作者: ${commit.author}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            '时间: ${_formatDate(commit.date)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            'Hash: ${commit.hash}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const Divider(height: 32),
                          Text(
                            '变更文件:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: _changedFiles
                                  .map((file) => ListTile(
                                        leading: _getStatusIcon(file.status),
                                        title: Text(file.path),
                                        subtitle: Text(_getStatusText(file.status)),
                                        selected: _selectedFilePath == file.path,
                                        onTap: () async {
                                          setState(() => _selectedFilePath = file.path);
                                          if (!_fileDiffs.containsKey(file.path)) {
                                            await _loadFileDiff(file.path);
                                          }
                                        },
                                        dense: true,
                                      ))
                                  .toList(),
                            ),
                          ),
                          const Divider(height: 32),
                          Row(
                            children: [
                              Text(
                                '变更内容:',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(width: 8),
                              if (_selectedFilePath != null)
                                Text(
                                  _selectedFilePath!,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SelectableText(
                              _selectedFilePath != null ? _fileDiffs[_selectedFilePath] ?? '加载中...' : '请选择一个文件查看变更',
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Icon _getStatusIcon(String status) {
    switch (status) {
      case 'M':
        return const Icon(Icons.edit, color: Colors.orange);
      case 'A':
        return const Icon(Icons.add_circle, color: Colors.green);
      case 'D':
        return const Icon(Icons.remove_circle, color: Colors.red);
      default:
        return const Icon(Icons.help);
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'M':
        return '已修改';
      case 'A':
        return '新增';
      case 'D':
        return '已删除';
      default:
        return '未知状态';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
