import 'package:flutter/material.dart';
import 'package:gitok/layouts/search_box.dart';
import 'package:gitok/pages/config_page.dart';
import 'package:gitok/pages/welcome_page.dart';

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
    '设置': const ConfigPage(isEmbedded: true),
    '欢迎': const WelcomePage(),
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
      body: Column(
        children: [
          // 搜索框
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBox(
              controller: _searchController,
              onChanged: _handleSearch,
              onHome: () => setState(() => _selectedFeature = null),
            ),
          ),
          // 功能列表或选中的功能界面
          Expanded(
            child: _selectedFeature ?? _buildFeatureList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureList() {
    return ListView.builder(
      itemCount: _features.length,
      itemBuilder: (context, index) {
        final entry = _features.entries.elementAt(index);
        return ListTile(
          title: Text(entry.key),
          onTap: () => setState(() => _selectedFeature = entry.value),
        );
      },
    );
  }
}
