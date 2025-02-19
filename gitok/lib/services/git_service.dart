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

class GitService {
  static final GitService _instance = GitService._internal();
  factory GitService() => _instance;
  GitService._internal();

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
    final gitDir = Directory(path.join(dirPath, '.git'));
    return gitDir.existsSync();
  }

  Future<List<String>> getBranches(String repoPath) async {
    final gitPath = await _getGitPath();
    final result = await Process.run(
      gitPath,
      ['branch'],
      workingDirectory: repoPath,
      runInShell: true,
    );

    if (result.exitCode != 0) {
      throw Exception('Failed to get branches: ${result.stderr}');
    }

    final branches = (result.stdout as String)
        .split('\n')
        .where((branch) => branch.isNotEmpty)
        .map((branch) => branch.trim().replaceAll('* ', ''))
        .toList();

    return branches;
  }

  Future<String> getCurrentBranch(String repoPath) async {
    final gitPath = await _getGitPath();
    final result = await Process.run(
      gitPath,
      ['branch', '--show-current'],
      workingDirectory: repoPath,
      runInShell: true,
    );

    if (result.exitCode != 0) {
      throw Exception('Failed to get current branch: ${result.stderr}');
    }

    return (result.stdout as String).trim();
  }

  Future<void> checkout(String repoPath, String branch) async {
    final gitPath = await _getGitPath();
    final result = await Process.run(
      gitPath,
      ['checkout', branch],
      workingDirectory: repoPath,
      runInShell: true,
    );

    if (result.exitCode != 0) {
      throw Exception('Failed to checkout branch: ${result.stderr}');
    }
  }

  Future<void> pull(String repoPath) async {
    final gitPath = await _getGitPath();
    final result = await Process.run(
      gitPath,
      ['pull'],
      workingDirectory: repoPath,
      runInShell: true,
    );

    if (result.exitCode != 0) {
      throw GitException(
        command: 'pull',
        message: result.stderr as String,
        exitCode: result.exitCode,
      );
    }
  }

  Future<void> commit(String repoPath, String message) async {
    final gitPath = await _getGitPath();

    // First add all changes
    var addResult = await Process.run(
      gitPath,
      ['add', '.'],
      workingDirectory: repoPath,
      runInShell: true,
    );

    if (addResult.exitCode != 0) {
      throw GitException(
        command: 'add',
        message: addResult.stderr as String,
        exitCode: addResult.exitCode,
      );
    }

    // Then commit
    final commitResult = await Process.run(
      gitPath,
      ['commit', '-m', message],
      workingDirectory: repoPath,
      runInShell: true,
    );

    if (commitResult.exitCode != 0) {
      throw GitException(
        command: 'commit',
        message: commitResult.stderr as String,
        exitCode: commitResult.exitCode,
      );
    }
  }

  Future<void> push(String repoPath) async {
    final gitPath = await _getGitPath();
    final result = await Process.run(
      gitPath,
      ['push'],
      workingDirectory: repoPath,
      runInShell: true,
    );

    if (result.exitCode != 0) {
      throw Exception('Failed to push: ${result.stderr}');
    }
  }

  Future<List<CommitInfo>> getCommitHistory(String repoPath) async {
    final gitPath = await _getGitPath();

    final result = await Process.run(
      gitPath,
      ['log', '--pretty=format:%H|%an|%ad|%s', '--date=iso'],
      workingDirectory: repoPath,
      runInShell: true,
    );

    if (result.exitCode != 0) {
      throw GitException(
        command: 'log',
        message: result.stderr as String,
        exitCode: result.exitCode,
      );
    }

    final output = result.stdout as String;
    if (output.isEmpty) return [];

    return output.split('\n').map((line) {
      final parts = line.split('|');
      return CommitInfo(
        hash: parts[0],
        author: parts[1],
        date: DateTime.parse(parts[2]),
        message: parts[3],
      );
    }).toList();
  }
}
