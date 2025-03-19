import 'package:flutter/material.dart';
import 'package:gitok/core/contract/plugin_status.dart';
import 'plugin_action.dart';
import 'plugin_context.dart';

/// 插件接口
///
/// 定义了插件需要实现的基本功能：
/// 1. 插件基本信息（ID、名称、作者等）
/// 2. 响应用户查询
/// 3. 处理用户动作
/// 4. 生命周期管理
abstract class Plugin {
  /// 插件唯一标识
  String get id;

  /// 插件名称
  String get name;

  /// 插件作者
  String get author;

  /// 插件版本
  String get version;

  /// 插件描述
  String get description;

  /// 插件图标
  IconData get icon;

  /// 插件是否启用
  bool get enabled;

  /// 插件当前状态
  PluginStatus? get status => null;

  /// 初始化插件
  Future<void> initialize();

  /// 响应用户查询
  ///
  /// [keyword] 用户输入的关键词
  /// [context] 插件运行时上下文
  /// 返回与关键词相关的动作列表
  Future<List<PluginAction>> onQuery(String keyword, [PluginContext context = const PluginContext()]);

  /// 处理用户选择的动作
  ///
  /// [actionId] 动作ID
  /// [buildContext] 构建上下文
  /// [pluginContext] 插件运行时上下文
  Future<void> onAction(String actionId, BuildContext buildContext,
      [PluginContext pluginContext = const PluginContext()]);

  /// 销毁插件
  Future<void> dispose();
}
