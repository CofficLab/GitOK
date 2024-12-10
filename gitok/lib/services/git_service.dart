import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:gitok/models/git_project.dart';

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
      throw Exception('Failed to pull: ${result.stderr}');
    }
  }

  Future<void> commit(String repoPath, String message) async {
    final gitPath = await _getGitPath();
    final result = await Process.run(
      gitPath,
      ['commit', '-m', message],
      workingDirectory: repoPath,
      runInShell: true,
    );

    if (result.exitCode != 0) {
      throw Exception('Failed to commit: ${result.stderr}');
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
}
