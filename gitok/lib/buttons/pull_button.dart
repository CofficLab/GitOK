import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gitok/providers/git_provider.dart';
import 'package:gitok/services/git_service.dart';

/// 拉取代码按钮组件
class PullButton extends StatelessWidget {
  const PullButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      icon: const Icon(Icons.download),
      label: Consumer<GitProvider>(
        builder: (context, gitProvider, child) => gitProvider.isPulling
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('拉取中...'),
                ],
              )
            : const Text('拉取'),
      ),
      onPressed: () async {
        final gitProvider = context.read<GitProvider>();
        if (gitProvider.isPulling) return;
        try {
          gitProvider.setPulling(true);
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
        } finally {
          gitProvider.setPulling(false);
        }
      },
    );
  }
}