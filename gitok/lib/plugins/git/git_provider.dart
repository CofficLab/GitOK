import 'package:flutter/foundation.dart';
import 'package:gitok/plugins/git/git_service.dart';
import 'package:gitok/plugins/git/git_project.dart';
import 'package:gitok/plugins/git/models/commit_info.dart';

/// 右侧面板显示类型
enum RightPanelType { commitForm, commitDetail }

/// Git状态管理器
///
/// 负责管理Git相关的状态，包括：
/// - 当前项目：当前选中的Git项目
/// - 当前分支：项目当前所在的Git分支
/// - 分支列表：项目的所有Git分支
/// - 选中的提交：当前查看的历史提交
/// - 提交列表：项目的所有历史提交
/// - 右侧面板类型：控制右侧面板显示提交表单或提交详情
class GitProvider extends ChangeNotifier {
  final GitService _gitService = GitService();

  /// 当前选中的Git项目
  GitProject? _currentProject;

  /// 当前所在的Git分支
  String _currentBranch = '';

  /// 项目的所有Git分支
  List<String> _branches = [];

  /// 当前查看的历史提交
  CommitInfo? _selectedCommit;

  /// 项目的所有历史提交
  List<CommitInfo> _commits = [];

  /// 右侧面板显示类型
  /// - commitForm: 显示提交表单，用于创建新的提交
  /// - commitDetail: 显示提交详情，查看历史提交的信息
  RightPanelType _rightPanelType = RightPanelType.commitForm;
  RightPanelType get rightPanelType => _rightPanelType;

  /// 是否正在推送代码
  bool _isPushing = false;
  bool get isPushing => _isPushing;

  bool _isPulling = false;
  bool get isPulling => _isPulling;

  /// 设置推送状态
  void setPushing(bool value) {
    _isPushing = value;
    notifyListeners();
  }

  /// 设置拉取状态
  void setPulling(bool value) {
    _isPulling = value;
    notifyListeners();
  }

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
    try {
      _currentBranch = await _gitService.getCurrentBranch(path);
    } catch (e) {
      // 获取当前分支失败时，设置为空字符串
      _currentBranch = '';
    }

    try {
      _branches = await _gitService.getBranches(path);
    } catch (e) {
      // 获取分支列表失败时，设置为空列表
      _branches = [];
    }
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
      final newCommits = await _gitService.getCommits(project.path);
      // 只在提交列表发生变化时才更新状态
      if (_commits.length != newCommits.length ||
          !_commits.asMap().entries.every((entry) => entry.value.hash == newCommits[entry.key].hash)) {
        _commits = newCommits;
        notifyListeners();
      }
    } catch (e) {
      if (_commits.isNotEmpty) {
        _commits = [];
        notifyListeners();
      }
    }
  }

  void notifyCommitsChanged() {
    notifyListeners();
  }

  Future<void> push() async {
    if (_currentProject == null) return;
    await _gitService.push(_currentProject!.path);
    await loadCommits(); // 刷新提交列表
    notifyListeners();
  }

  void notifyProjectsChanged() {
    notifyListeners();
  }

  /// 取消文件更改
  Future<void> discardFileChanges(String filePath) async {
    final project = currentProject;
    if (project == null) return;

    await _gitService.discardFileChanges(project.path, filePath);
    notifyListeners();
  }
}
