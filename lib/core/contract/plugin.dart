import 'package:flutter/widgets.dart';
import 'plugin_action.dart';

/// 插件接口
///
/// 定义了插件需要实现的基本方法和属性
abstract class Plugin {
  /// 插件的唯一标识
  String get id;

  /// 插件的名称
  String get name;

  /// 插件的描述
  String get description;

  /// 插件的版本
  String get version;

  /// 插件的作者
  String get author;

  /// 响应关键词
  ///
  /// [keyword] 用户输入的关键词
  /// 返回与关键词相关的动作列表
  Future<List<PluginAction>> onQuery(String keyword);

  /// 执行动作
  ///
  /// [actionId] 动作的唯一标识
  /// [context] 动作执行的上下文
  Future<void> onAction(String actionId, BuildContext context);

  /// 插件初始化
  ///
  /// 在插件被加载时调用
  Future<void> initialize() async {}

  /// 插件销毁
  ///
  /// 在插件被卸载时调用
  Future<void> dispose() async {}
}
