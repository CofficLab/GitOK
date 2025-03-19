import 'plugin.dart';
import 'plugin_action.dart';

/// 插件管理器接口
///
/// 定义了内核用于管理插件的方法
abstract class PluginManager {
  /// 注册插件
  Future<void> registerPlugin(Plugin plugin);

  /// 注销插件
  Future<void> unregisterPlugin(String pluginId);

  /// 获取所有已注册的插件
  List<Plugin> get plugins;

  /// 查询所有插件
  ///
  /// [keyword] 用户输入的关键词
  /// 返回所有插件响应的动作列表
  Future<List<PluginAction>> queryAll(String keyword);
}
