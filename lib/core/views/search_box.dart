import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:gitok/utils/logger.dart';

/// 搜索框组件
///
/// 一个美观的搜索输入框，支持：
/// 1. 自动获取焦点
/// 2. 清除按钮
/// 3. 搜索图标
/// 4. 整体区域可拖动窗口
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
    return Listener(
      onPointerDown: (event) {
        if (event.buttons == 1) {
          try {
            windowManager.startDragging();
          } catch (e) {
            Logger.error('SearchBox', '启动窗口拖动失败', e);
          }
        }
      },
      child: Stack(
        children: [
          // 搜索框
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: controller.text.isNotEmpty
                  ? MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          controller.clear();
                        },
                        child: const Icon(Icons.clear),
                      ),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            autofocus: autofocus,
          ),
        ],
      ),
    );
  }
}
