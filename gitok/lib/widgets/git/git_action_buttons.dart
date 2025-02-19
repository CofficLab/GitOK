import 'package:flutter/material.dart';

/// A widget that displays Git action buttons (pull and push).
class GitActionButtons extends StatelessWidget {
  final VoidCallback onPull;
  final VoidCallback onPush;

  const GitActionButtons({
    super.key,
    required this.onPull,
    required this.onPush,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.download),
          label: const Text('拉取'),
          onPressed: onPull,
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.upload),
          label: const Text('推送'),
          onPressed: onPush,
        ),
      ],
    );
  }
}
