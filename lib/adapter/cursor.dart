import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:gitok/utils/logger.dart';

/// Cursor 工具类
///
/// 提供 Cursor 相关的工具方法，包括：
/// 1. 获取当前打开的项目信息
/// 2. 读取 Cursor 配置文件
/// 3. 跨平台路径处理
class Cursor {
  static const String _tag = 'CursorUtils';

  /// 获取 Cursor 当前打开的项目目录
  static Future<String?> getActiveWorkspace() async {
    try {
      // 获取存储文件路径
      final storagePath = await _getStoragePath();
      if (storagePath == null) {
        Logger.error(_tag, '无法获取 Cursor 存储文件路径');
        return null;
      }

      // 读取存储文件
      final file = File(storagePath);
      if (!await file.exists()) {
        Logger.error(_tag, 'Cursor 存储文件不存在: $storagePath');
        return null;
      }

      // 读取并解析 JSON 文件
      final content = await file.readAsString();
      return _parseCursorJson(content);
    } catch (e) {
      Logger.error(_tag, '获取 Cursor 工作区失败', e);
      return null;
    }
  }

  /// 解析 Cursor JSON 格式的存储文件
  static Future<String?> _parseCursorJson(String content) async {
    try {
      final json = jsonDecode(content) as Map<String, dynamic>;

      // 从 windowsState.lastActiveWindow.folder 获取工作区路径
      final windowState = json['windowsState'] as Map<String, dynamic>?;
      if (windowState != null) {
        final lastWindow = windowState['lastActiveWindow'] as Map<String, dynamic>?;
        if (lastWindow != null) {
          final folder = lastWindow['folder'] as String?;
          if (folder != null) {
            // 处理路径
            final decodedPath = Uri.decodeFull(folder);
            Logger.info(_tag, '找到 Cursor 工作区: $decodedPath');
            return decodedPath;
          }
        }
      }

      Logger.error(_tag, '无法从 JSON 中获取工作区路径');
      return null;
    } catch (e) {
      Logger.error(_tag, '解析 JSON 失败', e);
      return null;
    }
  }

  /// 获取 Cursor 存储文件路径
  static Future<String?> _getStoragePath() async {
    try {
      final home = Platform.environment['HOME'];
      if (Platform.isMacOS) {
        // macOS 上的存储位置
        final possiblePaths = [
          path.join(home!, 'Library/Application Support/Cursor/storage.json'),
          path.join(home!, 'Library/Application Support/Cursor/User/globalStorage/storage.json'),
        ];

        // 返回第一个存在的文件路径
        for (final filePath in possiblePaths) {
          Logger.debug(_tag, '检查路径: $filePath');
          if (await File(filePath).exists()) {
            Logger.debug(_tag, '找到 Cursor 存储文件: $filePath');
            return filePath;
          }
        }
      } else if (Platform.isWindows) {
        final appData = Platform.environment['APPDATA'];
        final possiblePaths = [
          path.join(appData!, 'Cursor/storage.json'),
          path.join(appData!, 'Cursor/User/globalStorage/storage.json'),
        ];

        for (final filePath in possiblePaths) {
          Logger.debug(_tag, '检查路径: $filePath');
          if (await File(filePath).exists()) {
            Logger.debug(_tag, '找到 Cursor 存储文件: $filePath');
            return filePath;
          }
        }
      } else if (Platform.isLinux) {
        final possiblePaths = [
          path.join(home!, '.config/Cursor/storage.json'),
          path.join(home!, '.config/Cursor/User/globalStorage/storage.json'),
        ];

        for (final filePath in possiblePaths) {
          Logger.debug(_tag, '检查路径: $filePath');
          if (await File(filePath).exists()) {
            Logger.debug(_tag, '找到 Cursor 存储文件: $filePath');
            return filePath;
          }
        }
      }

      Logger.error(_tag, '未找到 Cursor 存储文件');
      return null;
    } catch (e) {
      Logger.error(_tag, '获取存储文件路径失败', e);
      return null;
    }
  }
}
