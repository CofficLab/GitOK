import 'package:flutter/material.dart';

/// 搜索框组件
///
/// 一个美观的搜索输入框，支持：
/// 1. 自动获取焦点
/// 2. 清除按钮
/// 3. 搜索图标
class SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool autofocus;

  const SearchBox({
    super.key,
    required this.controller,
    this.hintText = '输入关键词搜索...',
    this.autofocus = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller.clear();
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      autofocus: autofocus,
    );
  }
}
