import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gitok/providers/git_provider.dart';
import 'package:gitok/services/git_service.dart';

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
      setState(() => _changes = changes);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('变动文件', style: Theme.of(context).textTheme.titleMedium),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadChanges,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_changes.isEmpty)
          const Center(child: Text('没有未提交的更改'))
        else
          Expanded(
            child: ListView.builder(
              itemCount: _changes.length,
              itemBuilder: (context, index) {
                final change = _changes[index];
                return ListTile(
                  leading: _getStatusIcon(change.status),
                  title: Text(change.path),
                  subtitle: Text(_getStatusText(change.status)),
                );
              },
            ),
          ),
      ],
    );

    if (StagedChanges.kDebugLayout) {
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
