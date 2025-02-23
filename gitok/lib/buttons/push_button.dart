import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gitok/providers/git_provider.dart';

/// 推送代码按钮组件
class PushButton extends StatelessWidget {
  const PushButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GitProvider>(
      builder: (context, gitProvider, child) => IconButton(
        icon: gitProvider.isPushing
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.upload),
        tooltip: '推送',
        onPressed: () async {
          final gitProvider = context.read<GitProvider>();
          if (gitProvider.isPushing) return;
          try {
            gitProvider.setPushing(true);
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
          } finally {
            gitProvider.setPushing(false);
          }
        },
      ),
    );
  }
}
