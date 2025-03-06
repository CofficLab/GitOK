import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gitok/plugins/git/git_provider.dart';
import 'package:gitok/plugins/git/git_service.dart';

/// 拉取代码按钮组件
class PullButton extends StatelessWidget {
  const PullButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GitProvider>(
      builder: (context, gitProvider, child) => IconButton(
        icon: gitProvider.isPulling
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.download),
        tooltip: '拉取',
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
      ),
    );
  }
}
