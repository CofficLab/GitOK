import 'package:flutter/material.dart';

/// GitOK应用程序的顶部应用栏组件。
///
/// 包含：
/// - 应用程序标题
/// - 添加项目按钮
///
/// 该组件实现了 [PreferredSizeWidget] 接口以符合 [AppBar] 的要求。
class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// 是否启用调试模式以突出显示布局边界
  static const bool kDebugLayout = true;

  /// 点击添加项目按钮时的回调函数
  final VoidCallback onAddProject;

  const HomeAppBar({
    super.key,
    required this.onAddProject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: kDebugLayout
          ? BoxDecoration(
              border: Border.all(color: Colors.purple, width: 2),
              color: Colors.purple.withOpacity(0.1),
            )
          : null,
      child: AppBar(
        title: const Text('GitOK'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('添加项目'),
              onPressed: onAddProject,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
