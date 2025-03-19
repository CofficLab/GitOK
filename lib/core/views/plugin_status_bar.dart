import 'package:flutter/material.dart';
import '../contract/plugin_protocol.dart';

/// 插件状态栏组件
///
/// 显示当前已注册的插件状态，包括：
/// 1. 插件图标
/// 2. 鼠标悬停时显示插件名称
/// 3. 插件启用状态的视觉反馈
class PluginStatusBar extends StatelessWidget {
  final List<Plugin> plugins;

  const PluginStatusBar({
    super.key,
    required this.plugins,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          // 已注册插件数量
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${plugins.length} 个插件',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          const SizedBox(width: 16),
          // 插件图标列表
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: plugins.map((plugin) {
                  return Tooltip(
                    message: '${plugin.name} ${plugin.version}\n${plugin.description}',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        plugin.icon,
                        size: 20,
                        color: plugin.enabled ? Theme.of(context).iconTheme.color : Theme.of(context).disabledColor,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
