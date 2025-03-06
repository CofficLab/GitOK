import 'package:path/path.dart' as path;

/// 配置管理服务
///
/// 统一管理应用的配置文件存储
class ConfigService {
  static String getConfigPath(String projectPath, String type) {
    return path.join(projectPath, '.gitok', type);
  }
}
