import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:gitok/providers/git_provider.dart';

/// Finder打开按钮组件
class FinderButton extends StatelessWidget {
  const FinderButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.folder),
      tooltip: 'Finder打开',
      onPressed: () async {
        final gitProvider = context.read<GitProvider>();
        if (gitProvider.currentProject == null) return;

        final path = gitProvider.currentProject!.path;
        await Process.run('open', [path]);
      },
    );
  }
}