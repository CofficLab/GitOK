import 'package:flutter/material.dart';
import '../../core/contract/plugin_protocol.dart';
import 'config_page.dart';

/// 设置功能插件
///
/// 提供应用程序的配置功能：
/// - 主题设置
/// - 快捷键配置
/// - 系统偏好设置
/// - Git全局配置
class ConfigPlugin implements Plugin {
  @override
  String get id => 'config';

  @override
  String get name => '系统设置';

  @override
  String get author => 'CofficLab';

  @override
  String get version => '1.0.0';

  @override
  IconData get icon => Icons.settings_rounded;

  @override
  String get description => '配置应用程序的主题、快捷键等设置';

  @override
  bool get enabled => true;

  @override
  Future<void> initialize() async {
    // 初始化配置，如果需要的话
  }

  @override
  Future<List<PluginAction>> onQuery(String keyword) async {
    if (keyword.isEmpty) return [];

    // 如果关键词包含"设置"、"config"等相关词，返回打开设置的动作
    final keywords = ['设置', 'config', '配置', '快捷键', 'hotkey'];
    if (keywords.any((k) => keyword.toLowerCase().contains(k.toLowerCase()))) {
      return [
        PluginAction(
          id: '$id:open_settings',
          title: '打开设置',
          icon: const Icon(Icons.settings),
          subtitle: '配置应用程序的主题、快捷键等',
        ),
      ];
    }

    return [];
  }

  @override
  Future<void> onAction(String actionId, BuildContext context) async {
    if (actionId == '$id:open_settings') {
      await showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Container(
            width: 600,
            height: 400,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.settings, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      '系统设置',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: '关闭',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Expanded(
                  child: ConfigPage(isEmbedded: true),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  @override
  Future<void> dispose() async {
    // 清理资源，如果需要的话
  }
}
