import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gitok/providers/git_provider.dart';
import 'package:gitok/services/git_service.dart';
import 'package:gitok/models/file_status.dart';
import 'package:gitok/tab_git/commit_detail/commit_info_panel.dart';
import 'package:gitok/tab_git/commit_detail/changed_files_list.dart';
import 'package:gitok/tab_git/commit_form.dart';
import 'package:gitok/tab_git/diff_viewer.dart';

/// Git提交详情展示组件
///
/// 展示单个Git提交的详细信息，包括：
/// - 完整的提交信息
/// - 提交的文件变更
/// - 具体的代码差异
class CommitDetail extends StatefulWidget {
  final bool isCurrentChanges; // 是否显示当前更改

  const CommitDetail({
    super.key,
    this.isCurrentChanges = false,
  });

  @override
  State<CommitDetail> createState() => _CommitDetailState();
}

class _CommitDetailState extends State<CommitDetail> {
  final GitService _gitService = GitService();
  List<FileStatus> _changedFiles = [];
  final Map<String, String> _fileDiffs = {};
  String? _selectedFilePath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final gitProvider = context.read<GitProvider>();
    final project = gitProvider.currentProject;
    if (project == null) return;

    setState(() => _isLoading = true);
    try {
      if (widget.isCurrentChanges) {
        // 加载当前未提交的变更
        _changedFiles = await _gitService.getStatus(project.path);
      } else {
        // 加载历史提交的变更
        final commit = gitProvider.selectedCommit;
        if (commit != null) {
          _changedFiles = await _gitService.getCommitFiles(project.path, commit.hash);
        }
      }

      // 如果有变更文件，自动选中第一个
      if (_changedFiles.isNotEmpty) {
        _selectedFilePath = _changedFiles[0].path;
        if (widget.isCurrentChanges) {
          // 对于当前状态，根据文件状态选择合适的差异命令
          final file = _changedFiles[0];
          final diff = file.status == 'M'
              ? await _gitService.getUnstagedFileDiff(project.path, file.path)
              : await _gitService.getStagedFileDiff(project.path, file.path);
          setState(() => _fileDiffs[file.path] = diff);
        } else {
          await _loadFileDiff(_selectedFilePath!);
        }
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void didUpdateWidget(CommitDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当切换显示模式（当前更改/历史提交）时重新加载
    if (oldWidget.isCurrentChanges != widget.isCurrentChanges) {
      _loadDetails();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 监听 GitProvider 状态变化，当状态变化时重新加载
    if (widget.isCurrentChanges) {
      _loadDetails();
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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _changedFiles.isEmpty
              ? _buildEmptyState(context)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.isCurrentChanges)
                      const CommitForm()
                    else
                      Consumer<GitProvider>(
                        builder: (context, gitProvider, _) {
                          final commit = gitProvider.selectedCommit;
                          if (commit == null) {
                            return const Text('👈 请选择一个提交查看详情');
                          }
                          return CommitInfoPanel(commit: commit);
                        },
                      ),
                    ChangedFilesList(
                      files: _changedFiles,
                      selectedPath: _selectedFilePath,
                      onFileSelected: _handleFileSelected,
                    ),
                    if (_selectedFilePath != null) ...[
                      const SizedBox(height: 16),
                      _buildDiffViewer(),
                    ],
                  ],
                ),
    );
  }

  Widget _buildDiffViewer() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('变更内容:', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(width: 8),
              Text(_selectedFilePath!, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: DiffViewer(
              diffText: _fileDiffs[_selectedFilePath] ?? '加载中...',
            ),
          ),
        ],
      ),
    );
  }

  /// 构建空状态界面
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.task_alt,
            size: 64,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          Text(
            '干净溜溜 ✨',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            widget.isCurrentChanges ? '当前没有任何文件变更\n你可以安心修改代码啦 🎯' : '这个提交没有任何文件变更\n可能是配置类的变更 🤔',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
          ),
          if (widget.isCurrentChanges) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadDetails,
              icon: const Icon(Icons.refresh),
              label: const Text('刷新'),
            ),
          ],
        ],
      ),
    );
  }

  void _handleFileSelected(FileStatus file) async {
    setState(() => _selectedFilePath = file.path);
    if (!_fileDiffs.containsKey(file.path)) {
      if (widget.isCurrentChanges) {
        final gitProvider = context.read<GitProvider>();
        final project = gitProvider.currentProject;
        if (project == null) return;

        final diff = file.status == 'M'
            ? await _gitService.getUnstagedFileDiff(project.path, file.path)
            : await _gitService.getStagedFileDiff(project.path, file.path);
        setState(() {
          _fileDiffs[file.path] = diff;
        });
      } else {
        await _loadFileDiff(file.path);
      }
    }
  }
}
