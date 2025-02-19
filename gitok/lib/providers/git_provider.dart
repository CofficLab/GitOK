import 'package:flutter/foundation.dart';
import 'package:gitok/services/git_service.dart';
import 'package:gitok/models/git_project.dart';
import 'package:gitok/models/commit_info.dart';

/// 右侧面板显示类型
enum RightPanelType { commitForm, commitDetail }

/// Git状态管理器
///
/// 负责管理Git相关的状态，包括：
/// - 当前项目
/// - 当前分支
/// - 分支列表
class GitProvider extends ChangeNotifier {
  final GitService _gitService = GitService();

  GitProject? _currentProject;
  String _currentBranch = '';
  List<String> _branches = [];
  CommitInfo? _selectedCommit;
  List<CommitInfo> _commits = [];

  RightPanelType _rightPanelType = RightPanelType.commitForm;
  RightPanelType get rightPanelType => _rightPanelType;

  GitProject? get currentProject => _currentProject;
  String get currentBranch => _currentBranch;
  List<String> get branches => _branches;
  CommitInfo? get selectedCommit => _selectedCommit;
  List<CommitInfo> get commits => _commits;

  Future<void> setCurrentProject(GitProject? project) async {
    _currentProject = project;
    if (project != null) {
      await _loadBranches(project.path);
      await loadCommits();
    } else {
      _currentBranch = '';
      _branches = [];
      _commits = [];
    }
    notifyListeners();
  }

  Future<void> _loadBranches(String path) async {
    _currentBranch = await _gitService.getCurrentBranch(path);
    _branches = await _gitService.getBranches(path);
    notifyListeners();
  }

  Future<void> switchBranch(String branch) async {
    if (_currentProject == null) return;

    await _gitService.checkout(_currentProject!.path, branch);
    _currentBranch = branch;
    notifyListeners();
  }

  void showCommitForm() {
    _rightPanelType = RightPanelType.commitForm;
    notifyListeners();
  }

  void setSelectedCommit(CommitInfo? commit) {
    _selectedCommit = commit;
    if (commit != null) {
      _rightPanelType = RightPanelType.commitDetail;
    }
    notifyListeners();
  }

  /// 提交更改
  Future<void> commit(String message) async {
    final project = currentProject;
    if (project == null) return;

    await _gitService.commit(project.path, message);

    // 提交后刷新所有状态
    await loadCommits();
    notifyListeners();
  }

  Future<void> loadCommits() async {
    final project = currentProject;
    if (project == null) return;

    try {
      _commits = await _gitService.getCommits(project.path);
      notifyListeners();
    } catch (e) {
      print('加载提交历史失败: $e');
      _commits = [];
    }
  }
}
