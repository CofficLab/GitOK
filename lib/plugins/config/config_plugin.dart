import 'package:flutter/material.dart';
import 'package:gitok/plugins/config/config_page.dart';
import 'package:gitok/core/contract/plugin_protocol.dart';

/// 设置功能插件
///
/// 提供应用程序的配置功能：
/// - 主题设置
/// - 快捷键配置
/// - 系统偏好设置
/// - Git全局配置
class ConfigPlugin implements PluginProtocol {
  @override
  String get name => '系统设置';

  @override
  IconData get icon => Icons.settings_rounded;

  @override
  String get description => '配置应用程序的主题、快捷键等设置';

  @override
  bool get enabled => true;

  @override
  Widget build(BuildContext context) {
    return const ConfigPage(isEmbedded: true);
  }
}
