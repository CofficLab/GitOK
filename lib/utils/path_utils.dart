import 'package:gitok/utils/logger.dart';
import 'dart:io' show Directory, Platform;

/// 路径工具类
///
/// 提供各种路径处理的实用方法，包括：
/// 1. URI 路径转换为本地文件系统路径
/// 2. 工作区路径的规范化
/// 3. 其他路径相关的工具方法
class PathUtils {
  static const String _tag = 'PathUtils';

  /// 将 URI 格式的路径转换为本地文件系统路径
  ///
  /// 例如：将 'file:///Users/name/path' 转换为 '/Users/name/path'
  /// 如果输入路径不是 file:// URI 格式，则返回原始路径
  static String normalizeUri(String path) {
    try {
      final uri = Uri.parse(path);
      if (uri.scheme == 'file') {
        return uri.toFilePath();
      }
    } catch (e) {
      Logger.error(_tag, '解析路径失败: $path', e);
    }
    return path;
  }

  /// 规范化工作区路径
  ///
  /// 处理工作区路径，确保返回一个标准化的格式：
  /// 1. 处理 URI 格式的路径（如 file:///path）
  /// 2. 处理波浪号展开（如 ~/project）
  /// 3. 确保路径存在且是一个目录
  /// 4. 返回绝对路径
  ///
  /// 如果路径无效或不存在，返回 null
  static String? normalizeWorkspace(String? path) {
    if (path == null || path.isEmpty) {
      return null;
    }

    try {
      // 首先处理 URI 格式
      String normalizedPath = normalizeUri(path);

      // 处理波浪号展开
      if (normalizedPath.startsWith('~')) {
        final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
        if (home == null) {
          Logger.error(_tag, '无法获取用户主目录');
          return null;
        }
        normalizedPath = normalizedPath.replaceFirst('~', home);
      }

      // 转换为绝对路径并验证目录是否存在
      final directory = Directory(normalizedPath);
      if (!directory.existsSync()) {
        Logger.error(_tag, '工作区路径不存在: $normalizedPath');
        return null;
      }

      return directory.absolute.path;
    } catch (e) {
      Logger.error(_tag, '规范化工作区路径失败: $path', e);
      return null;
    }
  }
}
