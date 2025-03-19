import 'package:flutter/material.dart';
import 'plugin_action.dart';

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

  /// 初始化插件
  Future<void> initialize();

  /// 响应用户查询
  ///
  /// [keyword] 用户输入的关键词
  /// 返回与关键词相关的动作列表
  Future<List<PluginAction>> onQuery(String keyword);

  /// 处理用户选择的动作
  ///
  /// [actionId] 动作ID
  /// [context] 构建上下文
  Future<void> onAction(String actionId, BuildContext context);

  /// 销毁插件
  Future<void> dispose();
}
