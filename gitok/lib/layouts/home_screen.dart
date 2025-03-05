import 'package:flutter/material.dart';
import 'package:gitok/layouts/search_box.dart';
import 'package:gitok/features/git_feature.dart';
import 'package:gitok/features/config_feature.dart';
import 'package:gitok/features/welcome_feature.dart';
import 'package:window_manager/window_manager.dart';

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

  final _features = {
    'Git管理': const GitFeature(),
    '设置': const ConfigFeature(),
    '欢迎': const WelcomeFeature(),
    // 在这里添加更多功能
  };

  void _handleSearch(String query) {
    if (query.isEmpty) {
      setState(() => _selectedFeature = null);
      return;
    }

    // 简单的模糊匹配
    final matches = _features.entries.where((entry) => entry.key.toLowerCase().contains(query.toLowerCase())).toList();

    if (matches.length == 1) {
      setState(() => _selectedFeature = matches.first.value);
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
                child: _selectedFeature ?? _buildFeatureList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureList() {
    return ListView.builder(
      itemCount: _features.length,
      itemBuilder: (context, index) {
        final entry = _features.entries.elementAt(index);
        return ListTile(
          leading: Icon(_getFeatureIcon(entry.key)),
          title: Text(entry.key),
          onTap: () => setState(() => _selectedFeature = entry.value),
        );
      },
    );
  }

  IconData _getFeatureIcon(String feature) {
    return switch (feature) {
      'Git管理' => Icons.source_rounded,
      '设置' => Icons.settings_rounded,
      _ => Icons.extension_rounded,
    };
  }
}
