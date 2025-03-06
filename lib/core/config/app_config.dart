import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

/// 应用配置文件
///
/// 这个文件包含了应用的各种配置信息，如更新源地址、检查间隔等。
/// 通过集中管理这些配置，我们可以更容易地维护和修改应用设置。
class AppConfig {
  /// 自动更新配置
  static final autoUpdate = AutoUpdateConfig();
}

/// 自动更新相关配置
class AutoUpdateConfig {
  static String? _feedURL;
  static int? _checkInterval;
  static Map<String, dynamic>? _config;

  /// 更新源地址
  static Future<String> get feedURL async {
    if (_feedURL == null) {
      final config = await _loadConfig();
      _feedURL = config['auto_update']['feed_url'] as String;
    }
    return _feedURL!;
  }

  /// 检查更新的时间间隔（单位：秒）
  static Future<int> get checkInterval async {
    if (_checkInterval == null) {
      final config = await _loadConfig();
      _checkInterval = config['auto_update']['check_interval'] as int;
    }
    return _checkInterval!;
  }

  /// 加载配置文件
  static Future<Map<String, dynamic>> _loadConfig() async {
    if (_config != null) return _config!;

    try {
      final String configString = await rootBundle.loadString('pubspec.yaml');
      final YamlMap yamlMap = loadYaml(configString);
      _config = yamlMap['config'] as Map<String, dynamic>;
      return _config!;
    } catch (e) {
      // 如果读取失败，返回默认值
      _config = {
        'auto_update': {
          'feed_url': 'https://github.com/CofficLab/GitOK/releases/latest/download/appcast.xml',
          'check_interval': 3600,
        }
      };
      return _config!;
    }
  }
}
