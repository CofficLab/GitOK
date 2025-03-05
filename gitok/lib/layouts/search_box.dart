import 'package:flutter/material.dart';

/// 搜索框组件
///
/// 提供一个类似 Spotlight 的搜索体验，带有返回首页功能
class SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onHome;

  const SearchBox({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      autofocus: true,
      decoration: InputDecoration(
        hintText: '搜索功能...',
        prefixIcon: IconButton(
          icon: const Icon(Icons.home_rounded), // 使用圆润的房子图标 🏠
          tooltip: '返回首页',
          onPressed: () {
            controller.clear(); // 清空搜索框
            onHome(); // 触发回调
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        // fillColor: Theme.of(context).cardColor,
      ),
    );
  }
}
