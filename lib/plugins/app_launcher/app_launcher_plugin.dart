import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as path;
import '../../core/contract/plugin.dart';
import '../../core/contract/plugin_action.dart';
import '../../utils/logger.dart';

/// 应用启动器插件
///
/// 负责扫描系统中已安装的应用，并提供快速启动功能。
/// 功能：
/// 1. 扫描系统应用目录
/// 2. 扫描用户应用目录
/// 3. 根据关键词搜索应用
/// 4. 使用 open 命令启动应用
class AppLauncherPlugin implements Plugin {
  final _applications = <String, String>{};
  bool _initialized = false;

  @override
  String get id => 'app_launcher';

  @override
  String get name => '应用启动器';

  @override
  String get description => '快速搜索并启动已安装的应用';

  @override
  String get version => '1.0.0';

  @override
  String get author => 'CofficLab';

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    Logger.info('AppLauncher', '初始化应用启动器插件');

    try {
      await _scanApplications();
      _initialized = true;
      Logger.info('AppLauncher', '应用启动器插件初始化完成');
    } catch (e) {
      Logger.error('AppLauncher', '应用启动器插件初始化失败', e);
      rethrow;
    }
  }

  /// 扫描系统中已安装的应用
  Future<void> _scanApplications() async {
    if (!Platform.isMacOS) {
      Logger.error('AppLauncher', '当前平台不支持：${Platform.operatingSystem}');
      return;
    }

    Logger.debug('AppLauncher', '开始扫描应用...');

    try {
      // 扫描系统应用目录
      await _scanDirectory('/Applications');

      // 扫描用户应用目录
      final userHome = Platform.environment['HOME'];
      if (userHome != null) {
        await _scanDirectory('$userHome/Applications');
      }

      Logger.debug('AppLauncher', '扫描完成，共发现 ${_applications.length} 个应用');
    } catch (e) {
      Logger.error('AppLauncher', '扫描应用失败', e);
      rethrow;
    }
  }

  /// 扫描指定目录下的应用
  Future<void> _scanDirectory(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      Logger.debug('AppLauncher', '目录不存在：$directoryPath');
      return;
    }

    try {
      await for (final entity in directory.list(recursive: false)) {
        if (entity is Directory || path.extension(entity.path) == '.app') {
          final appName = path.basenameWithoutExtension(entity.path);
          final normalizedName = appName.toLowerCase();
          _applications[normalizedName] = entity.path;
          Logger.debug('AppLauncher', '发现应用：$appName -> ${entity.path}');
        }
      }
    } catch (e) {
      Logger.error('AppLauncher', '扫描目录失败：$directoryPath', e);
    }
  }

  @override
  Future<List<PluginAction>> onQuery(String keyword) async {
    if (!_initialized) {
      Logger.error('AppLauncher', '插件尚未初始化');
      return [];
    }

    Logger.debug('AppLauncher', '搜索应用，关键词：$keyword');

    if (keyword.isEmpty) {
      return [];
    }

    final normalizedKeyword = keyword.toLowerCase();
    final actions = <PluginAction>[];

    // 根据关键词过滤应用
    for (final entry in _applications.entries) {
      if (entry.key.contains(normalizedKeyword)) {
        final appName = path.basenameWithoutExtension(entry.value);
        actions.add(PluginAction(
          id: '${id}:${entry.value}',
          title: appName,
          subtitle: '启动 $appName',
          score: _calculateScore(entry.key, normalizedKeyword),
        ));
      }
    }

    // 按分数排序
    actions.sort((a, b) => b.score.compareTo(a.score));

    Logger.debug('AppLauncher', '找到 ${actions.length} 个匹配的应用');
    return actions;
  }

  /// 计算应用名称与关键词的匹配分数
  double _calculateScore(String appName, String keyword) {
    if (appName == keyword) {
      return 1.0;
    } else if (appName.startsWith(keyword)) {
      return 0.8;
    } else if (appName.contains(keyword)) {
      return 0.6;
    } else {
      return 0.4;
    }
  }

  @override
  Future<void> onAction(String actionId, BuildContext context) async {
    Logger.info('AppLauncher', '执行动作：$actionId');

    if (!Platform.isMacOS) {
      throw Exception('当前平台不支持');
    }

    try {
      // 移除插件ID前缀
      final appPath = actionId.replaceFirst('$id:', '');
      final result = await Process.run('open', [appPath]);
      if (result.exitCode != 0) {
        final error = result.stderr.toString().trim();
        Logger.error('AppLauncher', '启动应用失败', error);
        throw Exception('启动应用失败：$error');
      }
      Logger.info('AppLauncher', '应用启动成功：$appPath');
    } catch (e) {
      Logger.error('AppLauncher', '启动应用失败', e);
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    Logger.info('AppLauncher', '销毁应用启动器插件');
    _applications.clear();
    _initialized = false;
  }
}
