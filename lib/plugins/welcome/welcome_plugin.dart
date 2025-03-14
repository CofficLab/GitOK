import 'package:flutter/material.dart';
import 'package:gitok/plugins/welcome/welcome_page.dart';
import 'package:gitok/core/contract/plugin_protocol.dart';

/// 欢迎功能插件
///
/// 提供应用程序的欢迎功能：
/// - 新手引导
/// - 功能介绍
/// - 快速入门教程
/// - 常见问题解答
class WelcomePlugin implements PluginProtocol {
  @override
  String get name => '欢迎';

  @override
  IconData get icon => Icons.waving_hand_rounded;

  @override
  String get description => '新手引导与功能介绍';

  @override
  bool get enabled => true;

  @override
  Widget build(BuildContext context) {
    return const WelcomePage();
  }
}
