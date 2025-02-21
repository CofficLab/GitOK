import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:gitok/providers/git_provider.dart';
import 'package:gitok/services/git_service.dart';

/// Git操作按钮组
///
/// 包含以下功能按钮：
/// - VS Code打开
/// - 浏览器打开
/// - Finder打开
/// - 终端打开
/// - 拉取代码
/// - 推送代码
class GitActionButtons extends StatelessWidget {
  const GitActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final gitProvider = context.watch<GitProvider>();
    if (gitProvider.currentProject == null) return const SizedBox.shrink();

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.code),
          tooltip: 'VS Code打开',
          onPressed: () async {
            final path = gitProvider.currentProject!.path;
            await Process.run('code', [path]);
          },
        ),
        IconButton(
          icon: const Icon(Icons.web),
          tooltip: '浏览器打开',
          onPressed: () async {
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
        ),
        IconButton(
          icon: const Icon(Icons.folder),
          tooltip: 'Finder打开',
          onPressed: () async {
            final path = gitProvider.currentProject!.path;
            await Process.run('open', [path]);
          },
        ),
        IconButton(
          icon: const Icon(Icons.terminal),
          tooltip: '终端打开',
          onPressed: () async {
            final path = gitProvider.currentProject!.path;
            await Process.run('open', ['-a', 'Terminal', path]);
          },
        ),
        const SizedBox(width: 16),
        FilledButton.icon(
          icon: const Icon(Icons.download),
          label: const Text('拉取'),
          onPressed: () async {
            try {
              await GitService().pull(gitProvider.currentProject!.path);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('拉取成功 🎉')),
              );
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('拉取失败: $e 😢')),
              );
            }
          },
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          icon: const Icon(Icons.upload),
          label: const Text('推送'),
          onPressed: () async {
            try {
              await gitProvider.push();
              gitProvider.notifyCommitsChanged();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('推送成功！🚀')),
                );
              }
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('推送失败: $e 😢')),
              );
            }
          },
        ),
      ],
    );
  }
}
