import 'package:flutter/material.dart';
import '../contract/plugin_action.dart';

/// 动作列表组件
///
/// 用于显示插件返回的动作列表，支持：
/// 1. 加载状态显示
/// 2. 空状态提示
/// 3. 动作项点击处理
/// 4. 键盘导航支持
/// 5. 选中状态高亮
class ActionList extends StatelessWidget {
  final bool isLoading;
  final List<PluginAction> actions;
  final String searchKeyword;
  final Function(PluginAction) onActionSelected;
  final int selectedIndex;

  const ActionList({
    super.key,
    required this.isLoading,
    required this.actions,
    required this.searchKeyword,
    required this.onActionSelected,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (actions.isEmpty) {
      return Center(
        child: Text(
          searchKeyword.isEmpty ? '输入关键词开始搜索 🔍' : '没有找到相关结果 😅',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return ListView.builder(
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        final isSelected = index == selectedIndex;

        return ListTile(
          leading: action.icon,
          title: Text(action.title),
          subtitle: action.subtitle != null ? Text(action.subtitle!) : null,
          trailing: isSelected ? const _KeyboardHint() : null,
          selected: isSelected,
          selectedTileColor: Theme.of(context).highlightColor,
          onTap: () => onActionSelected(action),
        );
      },
    );
  }
}

/// 键盘操作提示组件
class _KeyboardHint extends StatelessWidget {
  const _KeyboardHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Theme.of(context).dividerColor.withAlpha(51),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.keyboard_return,
            size: 16,
            color: Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            '回车',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }
}
