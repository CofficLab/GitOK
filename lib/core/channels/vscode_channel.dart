import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:gitok/utils/logger.dart';
import 'method_channel_manager.dart';

/// VSCode 通道管理器
///
/// 负责管理与 VSCode 相关的操作，包括：
/// 1. 获取当前打开的项目信息
/// 2. 读取工作区配置
/// 3. 跨平台支持
class VSCodeChannel extends MethodChannelManager {
  static const String _tag = 'VSCodeChannel';

  VSCodeChannel._() {
    Logger.debug(_tag, '创建 VSCode 通道实例');
  }

  static final VSCodeChannel instance = VSCodeChannel._();

  @override
  final channel = const MethodChannel('com.cofficlab.gitok/vscode');

  /// 获取 VSCode 当前打开的项目目录
  Future<String?> getActiveWorkspace() async {
    try {
      // 获取存储文件路径
      final storagePath = await _getStoragePath();
      if (storagePath == null) {
        Logger.error(_tag, '无法获取 VSCode 存储文件路径');
        return null;
      }

      // 读取存储文件
      final file = File(storagePath);
      if (!await file.exists()) {
        Logger.error(_tag, 'VSCode 存储文件不存在: $storagePath');
        return null;
      }

      // 解析 JSON 数据
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

      final workspaceStorage = json['openedPathsList'] as Map<String, dynamic>?;
      final workspaces = workspaceStorage?['entries'] as List<dynamic>?;

      if (workspaces == null || workspaces.isEmpty) {
        Logger.info(_tag, '未找到活跃的 VSCode 工作区');
        return null;
      }

      // 获取最后打开的工作区
      final lastWorkspace = workspaces.first as Map<String, dynamic>;
      final folderUri = lastWorkspace['folderUri'] as String?;

      if (folderUri == null) {
        Logger.error(_tag, '工作区 URI 为空');
        return null;
      }

      // 处理路径
      final cleanPath = folderUri.replaceFirst('file://', '');
      final decodedPath = Uri.decodeFull(cleanPath);

      Logger.info(_tag, '找到 VSCode 工作区: $decodedPath');
      return decodedPath;
    } catch (e) {
      Logger.error(_tag, '获取 VSCode 工作区失败', e);
      return null;
    }
  }

  /// 获取 VSCode 存储文件路径
  Future<String?> _getStoragePath() async {
    try {
      if (Platform.isMacOS) {
        final home = Platform.environment['HOME'];
        return path.join(home!, 'Library/Application Support/Code/storage.json');
      } else if (Platform.isWindows) {
        final appData = Platform.environment['APPDATA'];
        return path.join(appData!, 'Code/storage.json');
      } else if (Platform.isLinux) {
        final home = Platform.environment['HOME'];
        return path.join(home!, '.config/Code/storage.json');
      }

      Logger.error(_tag, '不支持的操作系统: ${Platform.operatingSystem}');
      return null;
    } catch (e) {
      Logger.error(_tag, '获取存储文件路径失败', e);
      return null;
    }
  }
}
