import 'package:flutter/widgets.dart';

/// 插件动作的数据结构
///
/// 表示一个具体的可执行动作，包含：
/// - id: 动作的唯一标识
/// - title: 动作的标题
/// - subtitle: 动作的副标题（可选）
/// - icon: 动作的图标（可选）
/// - score: 动作的相关度评分
class PluginAction {
  final String id;
  final String title;
  final String? subtitle;
  final Widget? icon;
  final double score;

  const PluginAction({
    required this.id,
    required this.title,
    this.subtitle,
    this.icon,
    this.score = 0.0,
  });
}
