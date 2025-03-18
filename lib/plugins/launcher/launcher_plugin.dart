import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gitok/core/contract/plugin_protocol.dart';
import 'package:gitok/plugins/launcher/launcher_provider.dart';
import 'package:gitok/plugins/launcher/launcher_view.dart';

/// 软件启动器插件
///
/// 允许用户:
/// - 搜索已安装的软件
/// - 查看软件列表
/// - 点击启动软件
class LauncherPlugin implements PluginProtocol {
  @override
  String get name => '软件启动器';

  @override
  IconData get icon => Icons.apps_rounded;

  @override
  String get description => '搜索并启动已安装的软件';

  @override
  bool get enabled => true;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LauncherProvider(),
      child: const LauncherView(),
    );
  }
}
