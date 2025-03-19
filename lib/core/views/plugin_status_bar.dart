import 'package:flutter/material.dart';
import 'package:gitok/core/contract/plugin.dart';
import 'package:gitok/core/providers/companion_provider.dart';
import 'package:gitok/utils/logger.dart';

/// 插件状态栏
///
/// 显示所有已加载插件的状态：
/// 1. 插件图标
/// 2. 状态信息
/// 3. 错误高亮
/// 4. 进度指示器
/// 5. 被覆盖的应用信息
class PluginStatusBar extends StatefulWidget {
  final List<Plugin> plugins;

  const PluginStatusBar({
    super.key,
    required this.plugins,
  });

  @override
  State<PluginStatusBar> createState() => _PluginStatusBarState();
}

class _PluginStatusBarState extends State<PluginStatusBar> {
  static const String _tag = 'PluginStatusBar';
  final _companionProvider = CompanionProvider();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    Logger.info(_tag, '初始化中...');
    _initializeCompanionProvider();
  }

  Future<void> _initializeCompanionProvider() async {
    Logger.info(_tag, '开始初始化 CompanionProvider');
    try {
      await _companionProvider.initialize();
      // Logger.info(_tag, 'CompanionProvider 初始化成功');
      // Logger.debug(_tag, '当前被覆盖的应用 - ${_companionProvider.overlaidAppName}');
      // Logger.debug(_tag, '准备添加监听器');
      _companionProvider.addListener(_handleCompanionStateChanged);
      setState(() {
        _isInitialized = true;
      });
      // Logger.info(_tag, '初始化完成');
    } catch (e) {
      Logger.error(_tag, '初始化失败', e);
    }
  }

  @override
  void dispose() {
    Logger.info(_tag, '准备清理...');
    if (_isInitialized) {
      // Logger.debug(_tag, '准备移除监听器');
      _companionProvider.removeListener(_handleCompanionStateChanged);
    }
    Logger.info(_tag, '清理完成');
    super.dispose();
  }

  void _handleCompanionStateChanged() {
    // Logger.info(_tag, '收到状态变化通知');
    // Logger.debug(_tag, '当前被覆盖的应用 - ${_companionProvider.overlaidAppName}');
    if (mounted) {
      Logger.debug(_tag, 'Widget已挂载，准备重新构建');
      setState(() {});
      // Logger.debug(_tag, '重新构建完成');
    } else {
      Logger.debug(_tag, 'Widget未挂载，跳过重新构建');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Logger.debug(_tag, '开始构建');
    // Logger.debug(_tag, '插件数量 - ${widget.plugins.length}');
    // Logger.debug(_tag, '被覆盖的应用 - ${_companionProvider.overlaidAppName}');

    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // 插件状态列表
          Expanded(
            child: Row(
              children: widget.plugins.map((plugin) {
                return _PluginStatusItem(plugin: plugin);
              }).toList(),
            ),
          ),
          // 被覆盖的应用信息
          if (_isInitialized && _companionProvider.overlaidAppName != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.layers_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _companionProvider.overlaidAppName!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (_companionProvider.workspace != null) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.folder_outlined,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _companionProvider.workspace!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 插件状态项
///
/// 显示单个插件的状态信息：
/// 1. 插件图标（根据状态变色）
/// 2. 状态提示
/// 3. 错误图标（如果有）
/// 4. 进度指示器（如果有）
class _PluginStatusItem extends StatelessWidget {
  final Plugin plugin;

  const _PluginStatusItem({
    required this.plugin,
  });

  @override
  Widget build(BuildContext context) {
    final status = plugin.status;
    final hasError = status?.isError ?? false;
    final hasProgress = status?.progress != null;

    return Tooltip(
      message: status?.message ?? plugin.description,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 插件图标
            Icon(
              plugin.icon,
              size: 16,
              color: _getIconColor(context, plugin.enabled, hasError, status != null),
            ),
            // 进度指示器或错误图标
            if (hasProgress) ...[
              const SizedBox(width: 4),
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  value: status!.progress,
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ] else if (hasError) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.error_outline,
                size: 12,
                color: Theme.of(context).colorScheme.error,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getIconColor(BuildContext context, bool enabled, bool hasError, bool hasStatus) {
    if (hasError) {
      return Theme.of(context).colorScheme.error;
    }
    if (!enabled) {
      return Theme.of(context).colorScheme.onSurface.withOpacity(0.38);
    }
    if (hasStatus) {
      return Theme.of(context).colorScheme.primary;
    }
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }
}
