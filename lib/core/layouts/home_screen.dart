import 'package:flutter/material.dart';
import 'package:gitok/core/layouts/search_box.dart';
import 'package:gitok/plugins/git/git_plugin.dart';
import 'package:gitok/plugins/config/config_plugin.dart';
import 'package:gitok/plugins/welcome/welcome_plugin.dart';
import 'package:gitok/plugins/launcher/launcher_plugin.dart';
import 'package:window_manager/window_manager.dart';
import 'package:gitok/core/contract/plugin_protocol.dart';

/// GitOK应用程序的主屏幕。
/// 提供一个搜索式界面，用户可以通过搜索快速访问不同功能。
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Widget? _selectedFeature;
  final _searchController = TextEditingController();

  final List<PluginProtocol> _plugins = [
    GitPlugin(),
    ConfigPlugin(),
    WelcomePlugin(),
    LauncherPlugin(),
  ];

  void _handleSearch(String query) {
    if (query.isEmpty) {
      setState(() => _selectedFeature = null);
      return;
    }

    // 简单的模糊匹配
    final matches = _plugins.where((plugin) => plugin.name.toLowerCase().contains(query.toLowerCase())).toList();

    if (matches.length == 1) {
      setState(() => _selectedFeature = matches.first.build(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        margin: const EdgeInsets.all(0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // 将整个顶部区域包装为可拖动区域
            DragToMoveArea(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SearchBox(
                      controller: _searchController,
                      onChanged: _handleSearch,
                      onHome: () => setState(() => _selectedFeature = null),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _selectedFeature ?? _buildPluginList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPluginList() {
    return ListView.builder(
      itemCount: _plugins.length,
      itemBuilder: (context, index) {
        final plugin = _plugins[index];
        return ListTile(
          enabled: plugin.enabled,
          leading: Icon(plugin.icon),
          title: Text(plugin.name),
          subtitle: Text(plugin.description),
          onTap: () => setState(() => _selectedFeature = plugin.build(context)),
        );
      },
    );
  }
}
