import 'package:flutter/material.dart';

/// A widget that handles Git commit functionality.
class CommitSection extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onCommit;

  CommitSection({
    super.key,
    required this.controller,
    required this.onCommit,
  }) {
    // 如果文本控制器为空，设置默认的提交信息
    if (controller.text.isEmpty) {
      controller.text = '🎨 Chore: Minor adjustments';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '提交信息',
            hintText: '输入提交信息...',
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.save),
          label: const Text('提交更改'),
          onPressed: onCommit,
        ),
      ],
    );
  }
}
