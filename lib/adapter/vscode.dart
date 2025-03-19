import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:gitok/utils/logger.dart';
import 'package:sqlite3/sqlite3.dart';
import 'dart:math' as math;

/// VSCode 工具类
///
/// 提供 VSCode 相关的工具方法，包括：
/// 1. 获取当前打开的项目信息
/// 2. 读取 VSCode 配置文件
/// 3. 跨平台路径处理
class VSCode {
  static const String _tag = 'VSCodeUtils';

  /// 获取 VSCode 当前打开的项目目录
  static Future<String?> getActiveWorkspace() async {
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

      // 根据文件类型解析数据
      if (storagePath.endsWith('.vscdb')) {
        // SQLite 数据库文件
        Logger.info(_tag, '检测到 SQLite 数据库文件，尝试解析...');
        return _parseVSCodeDatabase(file);
      } else {
        // JSON 文件
        final content = await file.readAsString();
        return _parseVSCodeJson(content);
      }
    } catch (e) {
      Logger.error(_tag, '获取 VSCode 工作区失败', e);
      return null;
    }
  }

  /// 解析 VSCode JSON 格式的存储文件
  static Future<String?> _parseVSCodeJson(String content) async {
    try {
      final json = jsonDecode(content) as Map<String, dynamic>;

      // 尝试不同的数据结构
      String? folderUri;

      // 结构 1: openedPathsList.entries
      final workspaceStorage = json['openedPathsList'] as Map<String, dynamic>?;
      final workspaces = workspaceStorage?['entries'] as List<dynamic>?;
      if (workspaces != null && workspaces.isNotEmpty) {
        final lastWorkspace = workspaces.first as Map<String, dynamic>;
        folderUri = lastWorkspace['folderUri'] as String?;
      }

      // 结构 2: windowState.lastActiveWindow
      if (folderUri == null) {
        final windowState = json['windowState'] as Map<String, dynamic>?;
        final lastWindow = windowState?['lastActiveWindow'] as Map<String, dynamic>?;
        folderUri = lastWindow?['folderUri'] as String?;
      }

      if (folderUri == null) {
        Logger.error(_tag, '无法从 JSON 中获取工作区路径');
        return null;
      }

      // 处理路径
      final cleanPath = folderUri.replaceFirst('file://', '');
      final decodedPath = Uri.decodeFull(cleanPath);

      Logger.info(_tag, '找到 VSCode 工作区: $decodedPath');
      return decodedPath;
    } catch (e) {
      Logger.error(_tag, '解析 JSON 失败', e);
      return null;
    }
  }

  /// 解析 VSCode SQLite 数据库内容
  static Future<String?> _parseVSCodeDatabase(File file) async {
    Database? db;
    try {
      // 创建临时数据库文件
      final tempDir = await Directory.systemTemp.createTemp('vscode_db_');
      final tempPath = path.join(tempDir.path, 'state.vscdb');

      // 复制数据库文件到临时目录
      await file.copy(tempPath);

      // 打开数据库
      db = sqlite3.open(tempPath);

      // 获取表结构信息
      final tableInfo = db.select("SELECT * FROM sqlite_master WHERE type='table' AND name='ItemTable'");
      Logger.debug(_tag, '数据库表结构: ${tableInfo.first['sql']}');

      // 查询最近的工作区
      final results = db.select('''
        SELECT key, value FROM ItemTable 
        WHERE key LIKE '%window%'
           OR key LIKE '%workspace%'
           OR key LIKE '%folder%'
           OR key LIKE '%recent%'
           OR key LIKE '%history%'
           OR key LIKE '%state.global%'
           OR key = 'history.recentlyOpenedPathsList'
        ORDER BY key
      ''');

      Logger.info(_tag, '查询到 ${results.length} 条记录');
      for (final row in results) {
        final key = row['key'] as String;
        final value = row['value'];
        Logger.info(_tag, '处理数据库记录 - Key: $key');

        if (value != null) {
          Logger.debug(_tag, '值类型: ${value.runtimeType}');
        }

        String jsonStr;
        if (value is List<int>) {
          // 如果是二进制数据，转换为字符串
          jsonStr = String.fromCharCodes(value);
        } else if (value is Uint8List) {
          // 如果是 Uint8List，转换为字符串
          jsonStr = String.fromCharCodes(value);
        } else if (value is String) {
          // 如果已经是字符串，直接使用
          jsonStr = value;
        } else {
          Logger.debug(_tag, '未知的值类型: ${value.runtimeType}，跳过');
          continue;
        }

        try {
          final data = jsonDecode(jsonStr);
          Logger.debug(_tag, '解析后的数据类型: ${data.runtimeType}');

          // 优化日志输出
          if (data is Map<String, dynamic>) {
            if (data.containsKey('entries') && data['entries'] is List) {
              final entries = data['entries'] as List;
              Logger.debug(_tag, '找到 entries 列表，共 ${entries.length} 条记录');
              // 只输出前两个条目的信息
              if (entries.isNotEmpty) {
                for (var i = 0; i < math.min(2, entries.length); i++) {
                  final entry = entries[i];
                  if (entry is Map<String, dynamic>) {
                    Logger.debug(_tag, '条目 ${i + 1}: ${entry['folderUri'] ?? entry['label'] ?? '未知路径'}');
                  }
                }
                if (entries.length > 2) {
                  Logger.debug(_tag, '... 还有 ${entries.length - 2} 条记录');
                }
              }
            } else {
              // 对于其他类型的 Map，只输出关键字段
              final keyFields = ['folderUri', 'workspace', 'lastActiveWindow'];
              final relevantData = Map.fromEntries(data.entries.where((e) => keyFields.contains(e.key)));
              if (relevantData.isNotEmpty) {
                Logger.debug(_tag, '关键数据: $relevantData');
              }
            }
          } else if (data is List) {
            Logger.debug(_tag, '列表数据，共 ${data.length} 条记录');
            // 只输出前两个条目
            if (data.isNotEmpty) {
              for (var i = 0; i < math.min(2, data.length); i++) {
                Logger.debug(_tag, '条目 ${i + 1}: ${_truncateString(data[i].toString())}');
              }
              if (data.length > 2) {
                Logger.debug(_tag, '... 还有 ${data.length - 2} 条记录');
              }
            }
          }

          // 处理包含 entries 的数据结构
          if (data is Map<String, dynamic> && data.containsKey('entries')) {
            final entries = data['entries'] as List?;
            if (entries != null && entries.isNotEmpty) {
              Logger.debug(_tag, '找到 entries 列表，共 ${entries.length} 条记录');
              for (final entry in entries) {
                if (entry is Map<String, dynamic>) {
                  final folderUri = entry['folderUri'] as String?;
                  if (folderUri != null) {
                    // 处理路径
                    String decodedPath;
                    if (folderUri.startsWith('file://')) {
                      final cleanPath = folderUri.replaceFirst('file://', '');
                      decodedPath = Uri.decodeFull(cleanPath);
                    } else {
                      decodedPath = Uri.decodeFull(folderUri);
                    }

                    Logger.info(_tag, '找到 VSCode 工作区: $decodedPath');
                    return decodedPath;
                  }
                }
              }
            }
            continue;
          }

          // 其他类型的数据处理保持不变
          if (key.contains('windowState')) {
            Logger.debug(_tag, '尝试解析窗口状态...');
            if (data is Map<String, dynamic>) {
              final lastWindow = data['lastActiveWindow'] as Map<String, dynamic>?;
              if (lastWindow != null) {
                Logger.debug(_tag, '找到最后活动窗口信息: $lastWindow');
                final folderUri = lastWindow['folderUri'] as String?;
                if (folderUri != null) {
                  // 处理路径
                  String decodedPath;
                  if (folderUri.startsWith('file://')) {
                    final cleanPath = folderUri.replaceFirst('file://', '');
                    decodedPath = Uri.decodeFull(cleanPath);
                  } else {
                    decodedPath = Uri.decodeFull(folderUri);
                  }

                  Logger.info(_tag, '找到 VSCode 工作区: $decodedPath');
                  return decodedPath;
                }

                // 如果没有找到，尝试从 workspace 获取
                final workspace = lastWindow['workspace'] as Map<String, dynamic>?;
                if (workspace != null) {
                  Logger.debug(_tag, '找到工作区信息: $workspace');
                  final workspacePath =
                      workspace['id'] as String? ?? workspace['folderUri'] as String? ?? workspace['path'] as String?;

                  if (workspacePath != null) {
                    // 处理路径
                    String decodedPath;
                    if (workspacePath.startsWith('file://')) {
                      final cleanPath = workspacePath.replaceFirst('file://', '');
                      decodedPath = Uri.decodeFull(cleanPath);
                    } else {
                      decodedPath = Uri.decodeFull(workspacePath);
                    }

                    Logger.info(_tag, '找到 VSCode 工作区: $decodedPath');
                    return decodedPath;
                  }
                }
              }
            }
            continue;
          }
        } catch (e) {
          Logger.debug(_tag, '解析记录失败: $e，继续尝试下一条记录');
          continue;
        }
      }

      // 清理临时文件
      await tempDir.delete(recursive: true);

      Logger.error(_tag, '未能找到有效的工作区路径');
      return null;
    } catch (e) {
      Logger.error(_tag, '解析数据库失败', e);
      return null;
    } finally {
      db?.dispose();
    }
  }

  /// 获取 VSCode 存储文件路径
  static Future<String?> _getStoragePath() async {
    try {
      final home = Platform.environment['HOME'];
      if (Platform.isMacOS) {
        // macOS 上可能的存储位置
        final possiblePaths = [
          // 标准 VSCode
          path.join(home!, 'Library/Application Support/Code/storage.json'),
          path.join(home!, 'Library/Application Support/Code/User/globalStorage/state.vscdb'),
          path.join(home!, 'Library/Application Support/Code/User/globalStorage/storage.json'),
          // VSCode Insiders
          path.join(home!, 'Library/Application Support/Code - Insiders/storage.json'),
          path.join(home!, 'Library/Application Support/Code - Insiders/User/globalStorage/state.vscdb'),
          path.join(home!, 'Library/Application Support/Code - Insiders/User/globalStorage/storage.json'),
          // VSCodium
          path.join(home!, 'Library/Application Support/VSCodium/storage.json'),
          path.join(home!, 'Library/Application Support/VSCodium/User/globalStorage/state.vscdb'),
          path.join(home!, 'Library/Application Support/VSCodium/User/globalStorage/storage.json'),
        ];

        // 返回第一个存在的文件路径
        for (final filePath in possiblePaths) {
          Logger.debug(_tag, '检查路径: $filePath');
          if (await File(filePath).exists()) {
            Logger.debug(_tag, '找到 VSCode 存储文件: $filePath');
            return filePath;
          }
        }
      } else if (Platform.isWindows) {
        final appData = Platform.environment['APPDATA'];
        final possiblePaths = [
          // 标准 VSCode
          path.join(appData!, 'Code/storage.json'),
          path.join(appData!, 'Code/User/globalStorage/state.vscdb'),
          path.join(appData!, 'Code/User/globalStorage/storage.json'),
          // VSCode Insiders
          path.join(appData!, 'Code - Insiders/storage.json'),
          path.join(appData!, 'Code - Insiders/User/globalStorage/state.vscdb'),
          path.join(appData!, 'Code - Insiders/User/globalStorage/storage.json'),
          // VSCodium
          path.join(appData!, 'VSCodium/storage.json'),
          path.join(appData!, 'VSCodium/User/globalStorage/state.vscdb'),
          path.join(appData!, 'VSCodium/User/globalStorage/storage.json'),
        ];

        for (final filePath in possiblePaths) {
          Logger.debug(_tag, '检查路径: $filePath');
          if (await File(filePath).exists()) {
            Logger.debug(_tag, '找到 VSCode 存储文件: $filePath');
            return filePath;
          }
        }
      } else if (Platform.isLinux) {
        final possiblePaths = [
          // 标准 VSCode
          path.join(home!, '.config/Code/storage.json'),
          path.join(home!, '.config/Code/User/globalStorage/state.vscdb'),
          path.join(home!, '.config/Code/User/globalStorage/storage.json'),
          // VSCode Insiders
          path.join(home!, '.config/Code - Insiders/storage.json'),
          path.join(home!, '.config/Code - Insiders/User/globalStorage/state.vscdb'),
          path.join(home!, '.config/Code - Insiders/User/globalStorage/storage.json'),
          // VSCodium
          path.join(home!, '.config/VSCodium/storage.json'),
          path.join(home!, '.config/VSCodium/User/globalStorage/state.vscdb'),
          path.join(home!, '.config/VSCodium/User/globalStorage/storage.json'),
        ];

        for (final filePath in possiblePaths) {
          Logger.debug(_tag, '检查路径: $filePath');
          if (await File(filePath).exists()) {
            Logger.debug(_tag, '找到 VSCode 存储文件: $filePath');
            return filePath;
          }
        }
      }

      Logger.error(_tag, '未找到 VSCode 存储文件');
      return null;
    } catch (e) {
      Logger.error(_tag, '获取存储文件路径失败', e);
      return null;
    }
  }

  /// 截断字符串，使其不超过指定长度
  static String _truncateString(String str, [int maxLength = 100]) {
    if (str.length <= maxLength) return str;
    return '${str.substring(0, maxLength)}...';
  }
}
