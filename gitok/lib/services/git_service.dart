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

  Future<String> getCurrentBranch(String projectPath) async {
    if (kDebugService) {
      print('🌿 获取当前分支: $projectPath');
    }

    final result = await Process.run(
      'git',
      ['branch', '--show-current'],
      workingDirectory: projectPath,
    );

    if (result.exitCode != 0) {
      throw Exception('获取当前分支失败: ${result.stderr}');
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

  /// 获取指定提交的代码差异
  Future<String> getDiff(String projectPath, String commitHash) async {
    if (kDebugService) {
      print('🔍 获取差异: $projectPath - $commitHash');
    }

    final result = await Process.run(
      'git',
      ['show', commitHash], // 移除 --patch 参数，直接使用 show 命令
      workingDirectory: projectPath,
    );

    if (kDebugService) {
      print('📊 差异结果: ${result.exitCode == 0 ? '成功' : '失败'}');
      print('输出内容: ${result.stdout}'); // 添加输出内容的调试信息
      if (result.exitCode != 0) {
        print('错误信息: ${result.stderr}'); // 添加错误信息的调试信息
      }
    }

    if (result.exitCode != 0) {
      throw Exception('获取差异失败: ${result.stderr}');
    }

    return result.stdout as String;
  }

  /// 获取工作区状态
  Future<List<FileStatus>> getStatus(String projectPath) async {
    if (kDebugService) {
      print('📊 获取工作区状态: $projectPath');
    }

    final result = await Process.run(
      'git',
      ['status', '--porcelain'],
      workingDirectory: projectPath,
    );

    if (result.exitCode != 0) {
      throw Exception('获取状态失败: ${result.stderr}');
    }

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
    if (kDebugService) {
      print('📄 获取提交文件列表: $projectPath - $commitHash');
    }

    final result = await Process.run(
      'git',
      ['show', '--name-status', '--format=', commitHash],
      workingDirectory: projectPath,
    );

    if (result.exitCode != 0) {
      throw Exception('获取文件列表失败: ${result.stderr}');
    }

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
    if (kDebugService) {
      print('📄 获取文件差异: $projectPath - $commitHash - $filePath');
    }

    final result = await Process.run(
      'git',
      ['show', commitHash, '--', filePath],
      workingDirectory: projectPath,
    );

    if (result.exitCode != 0) {
      throw Exception('获取文件差异失败: ${result.stderr}');
    }

    return result.stdout as String;
  }

  /// 获取未提交的文件差异
  Future<String> getStagedFileDiff(String projectPath, String filePath) async {
    if (kDebugService) {
      print('📄 获取未提交文件差异: $projectPath - $filePath');
    }

    final result = await Process.run(
      'git',
      ['diff', 'HEAD', '--', filePath],
      workingDirectory: projectPath,
    );

    if (result.exitCode != 0) {
      throw Exception('获取文件差异失败: ${result.stderr}');
    }

    return result.stdout as String;
  }
}
