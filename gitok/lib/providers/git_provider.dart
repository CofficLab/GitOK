import 'package:flutter/foundation.dart';
import 'package:gitok/services/git_service.dart';
import 'package:gitok/models/git_project.dart';
import 'package:gitok/models/commit_info.dart';

/// Git状态管理器
///
/// 负责管理Git相关的状态，包括：
/// - 当前项目
/// - 当前分支
/// - 分支列表
class GitProvider with ChangeNotifier {
  final GitService _gitService = GitService();

  GitProject? _currentProject;
  String _currentBranch = '';
  List<String> _branches = [];
  CommitInfo? _selectedCommit;

  GitProject? get currentProject => _currentProject;
  String get currentBranch => _currentBranch;
  List<String> get branches => _branches;
  CommitInfo? get selectedCommit => _selectedCommit;

  Future<void> setCurrentProject(GitProject? project) async {
    _currentProject = project;
    if (project != null) {
      await _loadBranches(project.path);
    } else {
      _currentBranch = '';
      _branches = [];
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

  void setSelectedCommit(CommitInfo? commit) {
    _selectedCommit = commit;
    notifyListeners();
  }
}
