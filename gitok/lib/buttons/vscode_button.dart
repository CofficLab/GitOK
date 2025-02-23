import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:gitok/providers/git_provider.dart';

/// VS Code打开按钮组件
class VSCodeButton extends StatelessWidget {
  const VSCodeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.code),
      tooltip: 'VS Code打开',
      onPressed: () async {
        final gitProvider = context.read<GitProvider>();
        if (gitProvider.currentProject == null) return;
        
        final path = gitProvider.currentProject!.path;
        await Process.run('code', [path]);
      },
    );
  }
}