/// Git操作服务
///
/// 提供Git命令行操作的封装，包括：
/// - 分支管理（checkout、pull、push等）
/// - 仓库状态查询
/// - Git命令执行
///
/// 使用单例模式确保全局唯一实例

import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:gitok/exceptions/git_exception.dart';
import 'package:gitok/models/commit_info.dart';
import 'package:flutter/foundation.dart';
import 'package:gitok/models/file_status.dart';
import 'package:git/git.dart';

class GitService {
  static final GitService _instance = GitService._internal();
  factory GitService() => _instance;
  GitService._internal();

  static const bool kDebugService = true;

  Future<String> _getGitPath() async {
    if (Platform.isMacOS) {
      final locations = [
        '/usr/bin/git',
        '/usr/local/bin/git',
        '/opt/homebrew/bin/git',
      ];

      for (final location in locations) {
        if (await File(location).exists()) {
          return location;
        }
      }
      throw Exception('找不到 Git 可执行文件');
    }
    return 'git';
  }

  Future<bool> isGitRepository(String dirPath) async {
    try {
      await GitDir.isGitDir(dirPath);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> getBranches(String repoPath) async {
    final gitDir = await GitDir.fromExisting(repoPath);
    final branches = await gitDir.branches();
    return branches.map((branch) => branch.branchName).toList();
  }

  Future<String> getCurrentBranch(String projectPath) async {
    if (kDebugService) {
      print('🌿 获取当前分支: $projectPath');
    }

    final gitDir = await GitDir.fromExisting(projectPath);
    final result = await gitDir.runCommand(['branch', '--show-current']);
    return (result.stdout as String).trim();
  }

  Future<void> checkout(String repoPath, String branch) async {
    final gitDir = await GitDir.fromExisting(repoPath);
    await gitDir.runCommand(['checkout', branch]);
  }

  Future<void> pull(String repoPath) async {
    final gitDir = await GitDir.fromExisting(repoPath);
    await gitDir.runCommand(['pull']);
  }

  Future<void> commit(String repoPath, String message) async {
    final gitDir = await GitDir.fromExisting(repoPath);
    await gitDir.runCommand(['add', '.']);
    await gitDir.runCommand(['commit', '-m', message]);
  }

  Future<void> push(String repoPath) async {
    final gitDir = await GitDir.fromExisting(repoPath);
    await gitDir.runCommand(['push']);
  }

  Future<List<CommitInfo>> getCommitHistory(String repoPath) async {
    final gitDir = await GitDir.fromExisting(repoPath);
    final commits = await gitDir.runCommand(
      ['log', '--pretty=format:%H|%an|%ad|%s', '--date=iso'],
    );

    if (commits.stdout.toString().isEmpty) return [];

    return commits.stdout.toString().split('\n').map((line) {
      final parts = line.split('|');
      return CommitInfo(
        hash: parts[0],
        author: parts[1],
        date: DateTime.parse(parts[2]),
        message: parts[3],
      );
    }).toList();
  }

  /// 获取指定提交的代码差异
  Future<String> getDiff(String projectPath, String commitHash) async {
    final gitDir = await GitDir.fromExisting(projectPath);
    final result = await gitDir.runCommand(['show', commitHash]);
    return result.stdout as String;
  }

  /// 获取工作区状态
  Future<List<FileStatus>> getStatus(String projectPath) async {
    final gitDir = await GitDir.fromExisting(projectPath);
    final result = await gitDir.runCommand(['status', '--porcelain']);

    final List<FileStatus> changes = [];
    final lines = (result.stdout as String).split('\n');
    for (final line in lines) {
      if (line.isEmpty) continue;
      final status = line.substring(0, 2).trim();
      final path = line.substring(3);
      changes.add(FileStatus(path, status));
    }

    return changes;
  }

  /// 获取指定提交的变更文件列表
  Future<List<FileStatus>> getCommitFiles(String projectPath, String commitHash) async {
    final gitDir = await GitDir.fromExisting(projectPath);
    final result = await gitDir.runCommand(
      ['show', '--name-status', '--format=', commitHash],
    );

    final List<FileStatus> files = [];
    final lines = (result.stdout as String).split('\n');
    for (final line in lines) {
      if (line.isEmpty) continue;
      final parts = line.split('\t');
      if (parts.length >= 2) {
        files.add(FileStatus(parts[1], parts[0]));
      }
    }

    return files;
  }

  /// 获取指定提交中某个文件的差异
  Future<String> getFileDiff(String projectPath, String commitHash, String filePath) async {
    final gitDir = await GitDir.fromExisting(projectPath);
    final result = await gitDir.runCommand(['show', commitHash, '--', filePath]);
    return result.stdout as String;
  }

  /// 获取未提交的文件差异
  Future<String> getStagedFileDiff(String projectPath, String filePath) async {
    final gitDir = await GitDir.fromExisting(projectPath);
    final result = await gitDir.runCommand(['diff', 'HEAD', '--', filePath]);
    return result.stdout as String;
  }

  /// 获取未暂存文件的差异
  Future<String> getUnstagedFileDiff(String repoPath, String filePath) async {
    final gitDir = await GitDir.fromExisting(repoPath);
    final result = await gitDir.runCommand(['diff', filePath]);
    return result.stdout as String;
  }

  Future<List<CommitInfo>> getCommits(String path) async {
    return getCommitHistory(path);
  }
}
