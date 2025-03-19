import 'package:gitok/utils/logger.dart';

/// 路径工具类
///
/// 提供各种路径处理的实用方法，包括：
/// 1. URI 路径转换为本地文件系统路径
/// 2. 其他路径相关的工具方法
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
}
