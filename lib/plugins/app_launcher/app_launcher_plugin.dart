import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../../core/contract/plugin.dart';
import '../../core/contract/plugin_action.dart';
import '../../core/contract/plugin_protocol.dart';
import '../../utils/logger.dart';

/// 应用启动器插件
///
/// 提供应用程序快速启动功能：
/// 1. 扫描系统应用
/// 2. 快速搜索应用
/// 3. 一键启动应用
class AppLauncherPlugin implements Plugin {
  final Map<String, String> _applications = {};
  bool _isScanning = false;
  bool _hasScanned = false;

  @override
  String get id => 'app_launcher';

  @override
  String get name => '应用启动器';

  @override
  String get author => 'CofficLab';

  @override
  String get version => '1.0.0';

  @override
  IconData get icon => Icons.launch_rounded;

  @override
  String get description => '快速搜索并启动系统应用';

  @override
  bool get enabled => true;

  @override
  Future<void> initialize() async {
    Logger.info('AppLauncherPlugin', '正在初始化应用启动器...');
    // 在后台开始扫描应用
    _startScanningApplications();
  }

  /// 开始在后台扫描应用
  void _startScanningApplications() {
    if (_isScanning || _hasScanned) return;

    _isScanning = true;
    // 使用 Future.microtask 确保不阻塞主线程
    Future.microtask(() async {
      await _scanApplications();
      _isScanning = false;
      _hasScanned = true;
    });
  }

  /// 扫描系统应用
  Future<void> _scanApplications() async {
    Logger.info('AppLauncherPlugin', '开始扫描应用...');

    try {
      if (Platform.isMacOS) {
        const appDirs = [
          '/Applications',
          '/System/Applications',
        ];

        for (final dir in appDirs) {
          final directory = Directory(dir);
          if (!directory.existsSync()) continue;

          await for (final entry in directory.list(recursive: true)) {
            if (entry.path.endsWith('.app')) {
              final name = path.basenameWithoutExtension(entry.path);
              _applications[name.toLowerCase()] = entry.path;
              Logger.debug('AppLauncherPlugin', '发现应用: $name');
              // 每扫描一批应用就让出CPU，避免长时间占用
              await Future.delayed(const Duration(milliseconds: 1));
            }
          }
        }

        Logger.info('AppLauncherPlugin', '应用扫描完成，共发现 ${_applications.length} 个应用');
      }
    } catch (e) {
      Logger.error('AppLauncherPlugin', '扫描应用时出错', e);
    }
  }

  @override
  Future<List<PluginAction>> onQuery(String keyword) async {
    Logger.debug('AppLauncherPlugin', '搜索应用: $keyword');

    if (keyword.isEmpty) return [];

    // 如果还没开始扫描，启动扫描
    if (!_hasScanned && !_isScanning) {
      _startScanningApplications();
    }

    // 如果正在扫描，返回一个提示动作
    if (_isScanning) {
      return [
        PluginAction(
          id: '$id:scanning',
          title: '正在扫描应用...',
          icon: const Icon(Icons.hourglass_empty),
          subtitle: '请稍候再试',
        ),
      ];
    }

    final actions = <PluginAction>[];
    final lowerKeyword = keyword.toLowerCase();

    for (final entry in _applications.entries) {
      if (entry.key.contains(lowerKeyword)) {
        final name = path.basenameWithoutExtension(entry.value);
        actions.add(
          PluginAction(
            id: '$id:${entry.value}',
            title: name,
            icon: const Icon(Icons.laptop_mac),
            subtitle: '启动 $name',
          ),
        );
      }
    }

    Logger.debug('AppLauncherPlugin', '找到 ${actions.length} 个匹配的应用');
    return actions;
  }

  @override
  Future<void> onAction(String actionId, BuildContext context) async {
    // 如果是扫描中的提示动作，直接返回
    if (actionId == '$id:scanning') return;

    try {
      // 从动作ID中提取应用路径
      final appPath = actionId.replaceFirst('$id:', '');
      Logger.info('AppLauncherPlugin', '正在启动应用: $appPath');

      if (Platform.isMacOS) {
        await Process.run('open', [appPath]);
        Logger.info('AppLauncherPlugin', '应用启动成功');
      }
    } catch (e) {
      Logger.error('AppLauncherPlugin', '启动应用失败', e);
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    Logger.info('AppLauncherPlugin', '正在清理应用启动器...');
    _applications.clear();
    _isScanning = false;
    _hasScanned = false;
  }
}
