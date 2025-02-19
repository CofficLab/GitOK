import 'package:flutter/material.dart';
import 'package:gitok/models/file_status.dart';
import 'package:provider/provider.dart';
import 'package:gitok/providers/git_provider.dart';
import 'package:gitok/services/git_service.dart';
import 'package:gitok/widgets/git/diff_viewer.dart';

/// Git暂存区变动列表组件
class StagedChanges extends StatefulWidget {
  static const bool kDebugLayout = false;

  const StagedChanges({super.key});

  @override
  State<StagedChanges> createState() => _StagedChangesState();
}

class _StagedChangesState extends State<StagedChanges> {
  final GitService _gitService = GitService();
  List<FileStatus> _changes = [];
  Map<String, String> _fileDiffs = {};
  String? _selectedFilePath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadChanges();
  }

  Future<void> _loadChanges() async {
    final project = context.read<GitProvider>().currentProject;
    if (project == null) return;

    setState(() => _isLoading = true);
    try {
      final changes = await _gitService.getStatus(project.path);
      setState(() {
        _changes = changes;
        _selectedFilePath = changes.isNotEmpty ? changes[0].path : null;
      });
      if (_selectedFilePath != null) {
        await _loadFileDiff(_selectedFilePath!);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFileDiff(String filePath) async {
    final project = context.read<GitProvider>().currentProject;
    if (project == null) return;

    try {
      // 对于未提交的更改，使用特殊的差异命令
      final diff = await _gitService.getStagedFileDiff(project.path, filePath);
      setState(() => _fileDiffs[filePath] = diff);
    } catch (e) {
      setState(() => _fileDiffs[filePath] = '加载差异失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_changes.isEmpty) {
      return const Center(child: Text('没有未提交的更改'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('变动文件', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView(
            shrinkWrap: true,
            children: _changes
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
        if (_selectedFilePath != null) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Text('变更内容:', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(width: 8),
              Text(_selectedFilePath!, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 400),
            child: DiffViewer(
              diffText: _fileDiffs[_selectedFilePath] ?? '加载中...',
            ),
          ),
        ],
      ],
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
}
