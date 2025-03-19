import 'dart:async';
import 'package:flutter/material.dart';
import '../../utils/logger.dart';
import '../contract/plugin.dart';
import '../contract/plugin_action.dart';
import '../contract/plugin_context.dart';
import '../providers/companion_provider.dart';

/// 插件管理器 Provider
///
/// 负责管理所有插件的生命周期和调度。
/// 功能：
/// 1. 注册和注销插件
/// 2. 管理插件列表
/// 3. 分发查询请求到所有插件
/// 4. 合并和排序插件返回的动作列表
/// 5. 提供插件状态更新通知
class PluginManagerProvider extends ChangeNotifier {
  final _plugins = <String, Plugin>{};
  final _initializationCompleter = Completer<void>();
  final CompanionProvider _companionProvider;
  bool _initialized = false;

  /// 构造函数
  ///
  /// [companionProvider] 伙伴提供者，用于获取当前工作区和应用信息
  PluginManagerProvider(this._companionProvider) {
    Logger.debug('PluginManager', '创建插件管理器，使用伙伴提供者: ${_companionProvider.hashCode}');
  }

  List<Plugin> get plugins => _plugins.values.toList(growable: false);

  /// 获取当前上下文
  PluginContext _getCurrentContext() {
    return PluginContext(
      workspace: _companionProvider.workspace,
      overlaidAppName: _companionProvider.overlaidAppName,
      overlaidAppBundleId: _companionProvider.overlaidAppBundleId,
      overlaidAppProcessId: _companionProvider.overlaidAppProcessId,
    );
  }

  Future<void> _initialize() async {
    if (_initialized) return;

    try {
      Logger.info('PluginManager', '正在初始化所有插件...');

      // 等待所有插件初始化完成
      await Future.wait(
        _plugins.values.map((plugin) {
          Logger.debug('PluginManager', '初始化插件: ${plugin.id}');
          return plugin.initialize();
        }),
      );

      _initialized = true;
      _initializationCompleter.complete();
      Logger.info('PluginManager', '所有插件初始化完成');
      notifyListeners();
    } catch (e) {
      Logger.error('PluginManager', '插件初始化失败', e);
      _initializationCompleter.completeError(e);
      rethrow;
    }
  }

  Future<void> registerPlugin(Plugin plugin) async {
    Logger.info('PluginManager', '注册插件: ${plugin.id}');

    // 检查插件ID是否已存在
    if (_plugins.containsKey(plugin.id)) {
      throw Exception('插件 ${plugin.id} 已经注册');
    }

    // 注册插件
    _plugins[plugin.id] = plugin;

    // 如果管理器已经初始化完成，则初始化新插件
    if (_initialized) {
      Logger.debug('PluginManager', '初始化新插件: ${plugin.id}');
      await plugin.initialize();
    } else {
      // 如果是第一个插件，开始初始化过程
      if (_plugins.length == 1) {
        await _initialize();
      }
    }

    notifyListeners();
  }

  Future<void> unregisterPlugin(String pluginId) async {
    Logger.info('PluginManager', '注销插件: $pluginId');

    final plugin = _plugins[pluginId];
    if (plugin == null) {
      throw Exception('插件 $pluginId 未注册');
    }

    // 调用插件的销毁方法
    plugin.dispose();

    // 移除插件
    _plugins.remove(pluginId);
    notifyListeners();
  }

  /// 搜索动作
  Future<List<PluginAction>> search(String keyword) async {
    return queryAll(keyword);
  }

  Future<List<PluginAction>> queryAll(String keyword) async {
    // 等待初始化完成
    if (!_initialized) {
      Logger.debug('PluginManager', '等待插件初始化完成...');
      await _initializationCompleter.future;
    }

    if (_plugins.isEmpty) {
      Logger.info('PluginManager', '警告：没有注册任何插件');
      return [];
    }

    Logger.debug('PluginManager', '查询所有插件，关键词：$keyword');

    // 获取当前上下文
    final context = _getCurrentContext();
    Logger.debug('PluginManager', '当前上下文 - 工作区: ${context.workspace}');

    // 并行查询所有插件
    final futures = _plugins.values.map((plugin) async {
      try {
        return await plugin.onQuery(keyword, context);
      } catch (e) {
        Logger.error('PluginManager', '插件 ${plugin.id} 查询失败', e);
        return <PluginAction>[];
      }
    });

    // 等待所有插件返回结果
    final results = await Future.wait(futures);

    // 合并所有插件的结果
    final allActions = results.expand((actions) => actions).toList();

    // 按分数排序
    allActions.sort((a, b) => b.score.compareTo(a.score));

    Logger.debug('PluginManager', '共找到 ${allActions.length} 个动作');

    return allActions;
  }

  /// 执行动作
  Future<void> executeAction(PluginAction action, BuildContext buildContext) async {
    final pluginId = action.id.split(':')[0];
    final plugin = _plugins[pluginId];
    if (plugin == null) {
      throw Exception('找不到处理该动作的插件');
    }

    final context = _getCurrentContext();
    await plugin.onAction(action.id, buildContext, context);
  }

  Future<void> executeActionById(String actionId, BuildContext buildContext) async {
    final pluginId = actionId.split(':')[0];
    final plugin = _plugins[pluginId];
    if (plugin == null) {
      throw Exception('找不到处理该动作的插件');
    }

    final pluginContext = _getCurrentContext();
    await plugin.onAction(actionId, buildContext, pluginContext);
  }

  @override
  void dispose() {
    Logger.info('PluginManager', '销毁插件管理器');

    // 销毁所有插件
    for (final plugin in _plugins.values) {
      plugin.dispose();
    }
    _plugins.clear();
    _initialized = false;
    super.dispose();
  }
}
