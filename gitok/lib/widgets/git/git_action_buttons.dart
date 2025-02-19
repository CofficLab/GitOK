import 'package:flutter/material.dart';

/// A widget that displays Git action buttons (pull and push).
class GitActionButtons extends StatefulWidget {
  final Future<void> Function() onPull;
  final Future<void> Function() onPush;

  const GitActionButtons({
    super.key,
    required this.onPull,
    required this.onPush,
  });

  @override
  State<GitActionButtons> createState() => _GitActionButtonsState();
}

class _GitActionButtonsState extends State<GitActionButtons> {
  bool _isPulling = false;
  bool _isPushing = false;

  Future<void> _handlePull() async {
    if (_isPulling || _isPushing) return;
    setState(() => _isPulling = true);
    try {
      await widget.onPull();
    } finally {
      if (mounted) {
        setState(() => _isPulling = false);
      }
    }
  }

  Future<void> _handlePush() async {
    if (_isPushing || _isPulling) return;
    setState(() => _isPushing = true);
    try {
      await widget.onPush();
    } finally {
      if (mounted) {
        setState(() => _isPushing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ElevatedButton.icon(
          icon: _isPulling
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(),
                )
              : const Icon(Icons.download),
          label: const Text('拉取'),
          onPressed: _isPulling || _isPushing ? null : _handlePull,
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          icon: _isPushing
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(),
                )
              : const Icon(Icons.upload),
          label: const Text('推送'),
          onPressed: _isPushing || _isPulling ? null : _handlePush,
        ),
      ],
    );
  }
}
