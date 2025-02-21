import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gitok/providers/git_provider.dart';

/// Git提交表单组件
///
/// 用于输入提交信息并触发提交操作
class CommitForm extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onCommitted;

  const CommitForm({
    super.key,
    required this.controller,
    this.onCommitted,
  });

  /// 预设的提交信息模板
  static const Map<String, String> _presetMessages = {
    '✨ Feature': '✨ feat: implement new user interface',
    '🐛 Fix': '🐛 fix: resolve memory leak issue',
    '📝 Docs': '📝 docs: update README installation guide',
    '🎨 Style': '🎨 style: improve button and layout styles',
    '🔄 Refactor': '🔄 refactor: optimize code structure',
    '✅ Test': '✅ test: add unit tests for core functions',
    '🔧 Chore': '🔧 chore: update development configuration',
    '🚀 Perf': '🚀 perf: improve loading performance',
    '🔨 Build': '🔨 build: upgrade build system to latest version',
    '📦 Deps': '📦 deps: update dependencies to latest stable',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('提交信息', style: Theme.of(context).textTheme.titleMedium),
            PopupMenuButton<String>(
              tooltip: '选择预设的提交信息\nSelect a template with emoji ✨',
              icon: const Icon(Icons.auto_awesome),
              itemBuilder: (context) => _presetMessages.entries
                  .map(
                    (entry) => PopupMenuItem(
                      value: entry.value,
                      child: Tooltip(
                        message: entry.value,
                        child: Text(entry.key),
                      ),
                    ),
                  )
                  .toList(),
              onSelected: (value) {
                // 保存当前光标位置
                final currentPosition = controller.selection.baseOffset;
                final currentText = controller.text;

                // 如果当前文本为空，直接设置预设信息
                if (currentText.isEmpty) {
                  controller.text = value;
                  // 将光标移到末尾
                  controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: value.length),
                  );
                } else {
                  // 如果当前位置在开头，插入预设信息
                  if (currentPosition == 0) {
                    controller.text = value + currentText;
                    controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: value.length),
                    );
                  } else {
                    // 在当前位置插入预设信息
                    final newText =
                        currentText.substring(0, currentPosition) + value + currentText.substring(currentPosition);
                    controller.text = newText;
                    controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: currentPosition + value.length),
                    );
                  }
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '输入提交信息...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('重置'),
              onPressed: () => controller.clear(),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('提交'),
              onPressed: () async {
                try {
                  await context.read<GitProvider>().commit(controller.text);
                  controller.clear();
                  onCommitted?.call();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('提交成功 🎉'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('提交失败: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
