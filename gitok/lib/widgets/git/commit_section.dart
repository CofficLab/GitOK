import 'package:flutter/material.dart';
import 'package:gitok/widgets/git/staged_changes.dart';

/// Git提交表单组件
class CommitSection extends StatefulWidget {
  /// 是否启用调试模式以突出显示布局边界
  static const bool kDebugLayout = false;

  final TextEditingController controller;
  final VoidCallback onCommit;

  const CommitSection({
    super.key,
    required this.controller,
    required this.onCommit,
  });

  @override
  State<CommitSection> createState() => _CommitSectionState();
}

class _CommitSectionState extends State<CommitSection> {
  @override
  void initState() {
    super.initState();
    // 如果文本控制器为空，设置默认的提交信息
    if (widget.controller.text.isEmpty) {
      widget.controller.text = '🎨 Chore: Minor adjustments';
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 固定在顶部的提交表单
        Text('提交信息', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controller,
          decoration: const InputDecoration(
            hintText: '输入提交信息...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('提交'),
            onPressed: widget.onCommit,
          ),
        ),
        const SizedBox(height: 16),
        // 可滚动的变动列表区域
        const Expanded(
          child: StagedChanges(),
        ),
      ],
    );

    if (CommitSection.kDebugLayout) {
      content = Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.pink, width: 2),
          color: Colors.pink.withOpacity(0.1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: content,
        ),
      );
    }

    return content;
  }
}
