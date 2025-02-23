import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:gitok/providers/git_provider.dart';

/// 终端打开按钮组件
class TerminalButton extends StatelessWidget {
  const TerminalButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.terminal),
      tooltip: '终端打开',
      onPressed: () async {
        final gitProvider = context.read<GitProvider>();
        if (gitProvider.currentProject == null) return;

        final path = gitProvider.currentProject!.path;
        await Process.run('open', ['-a', 'Terminal', path]);
      },
    );
  }
}