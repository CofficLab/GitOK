import 'package:flutter/material.dart';

/// 插件协议
///
/// 定义了插件需要实现的基本接口：
/// - 插件名称
/// - 插件图标
/// - 插件描述
/// - 插件Widget
abstract class PluginProtocol {
  /// 插件名称
  String get name;

  /// 插件图标
  IconData get icon;

  /// 插件描述
  String get description;

  /// 插件是否启用
  bool get enabled => true;

  /// 构建插件界面
  Widget build(BuildContext context);
}
