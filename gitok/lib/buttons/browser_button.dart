import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:gitok/providers/git_provider.dart';

/// 浏览器打开按钮组件
class BrowserButton extends StatelessWidget {
  const BrowserButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.web),
      tooltip: '浏览器打开',
      onPressed: () async {
        final gitProvider = context.read<GitProvider>();
        if (gitProvider.currentProject == null) return;

        final path = gitProvider.currentProject!.path;
        final result = await Process.run(
          'git',
          ['config', '--get', 'remote.origin.url'],
          workingDirectory: path,
        );
        final url = result.stdout.toString().trim();
        if (url.isNotEmpty) {
          await Process.run('open', [url]);
        }
      },
    );
  }
}