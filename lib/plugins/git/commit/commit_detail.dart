import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gitok/plugins/git/git_provider.dart';
import 'package:gitok/plugins/git/git_service.dart';
import 'package:gitok/plugins/git/models/file_status.dart';
import 'package:gitok/plugins/git/commit/commit_info_panel.dart';
import 'package:gitok/plugins/git/commit/changed_files_list.dart';
import 'package:gitok/plugins/git/commit/commit_form.dart';
import 'package:gitok/plugins/git/diff_viewer.dart';

/// Git提交详情展示组件
///
/// 展示单个Git提交的详细信息，包括：
/// - 完整的提交信息（作者、时间、描述等）
/// - 提交涉及的文件变更列表
/// - 每个文件的具体代码差异
/// - 对于当前更改，显示提交表单
/// - 对于历史提交，显示提交信息面板
class CommitDetail extends StatefulWidget {
  /// 是否显示当前更改
  /// true: 显示工作区的未提交更改
  /// false: 显示历史提交的详细信息
  final bool isCurrentChanges;

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

  /// 加载提交详情
  /// - 当前更改：加载工作区和暂存区的文件状态
  /// - 历史提交：加载该提交涉及的文件变更
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: _loadDetails,
                  icon: const Icon(Icons.refresh),
                  label: const Text('刷新'),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: _showMergeBranchDialog,
                  icon: const Icon(Icons.merge_type),
                  label: const Text('合并分支'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // 显示合并分支对话框
  void _showMergeBranchDialog() async {
    final gitProvider = context.read<GitProvider>();
    final project = gitProvider.currentProject;
    if (project == null) return;

    // 获取所有分支
    List<String> branches = [];
    try {
      setState(() => _isLoading = true);
      branches = await _gitService.getBranches(project.path);
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('获取分支失败: $e 😅')));
      }
      return;
    }

    // 获取当前分支
    String currentBranch = '';
    try {
      currentBranch = await _gitService.getCurrentBranch(project.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('获取当前分支失败: $e 😅')));
      }
      return;
    }

    // 移除当前分支，因为不能自己合并自己
    branches.remove(currentBranch);

    if (branches.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('没有其他分支可合并 🤷‍♂️')));
      }
      return;
    }

    String? selectedBranch;

    if (!mounted) return;

    // 显示分支选择对话框
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('合并到 $currentBranch'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('选择要合并的源分支:'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                hint: const Text('选择分支'),
                items: branches
                    .map((branch) => DropdownMenuItem(
                          value: branch,
                          child: Text(branch),
                        ))
                    .toList(),
                onChanged: (value) {
                  selectedBranch = value;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (selectedBranch != null) {
                Navigator.pop(context);
                _mergeBranch(selectedBranch!, currentBranch);
              }
            },
            child: const Text('合并'),
          ),
        ],
      ),
    );
  }

  // 执行分支合并
  void _mergeBranch(String sourceBranch, String targetBranch) async {
    final gitProvider = context.read<GitProvider>();
    final project = gitProvider.currentProject;
    if (project == null) return;

    try {
      // 显示加载状态
      setState(() => _isLoading = true);

      // 执行合并
      final result = await _gitService.mergeBranch(project.path, sourceBranch);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('成功将 $sourceBranch 合并到 $targetBranch 🎉'),
          backgroundColor: Colors.green,
        ));
      }

      // 刷新状态
      _loadDetails();

      // 通知 GitProvider 刷新
      gitProvider.loadCommits();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('合并失败: $e 😢'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      setState(() => _isLoading = false);
    }
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
