import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gitok/providers/git_provider.dart';
import 'package:gitok/widgets/git/branch_switcher.dart';
import 'package:gitok/services/git_service.dart';
import 'package:process/process.dart';
import 'dart:io';

/// GitOK应用程序的顶部应用栏组件。
///
/// 包含：
/// - 应用程序标题
/// - 当前分支切换器
/// - 添加项目按钮
///
/// 该组件实现了 [PreferredSizeWidget] 接口以符合 [AppBar] 的要求。
class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// 是否启用调试模式以突出显示布局边界
  static const bool kDebugLayout = false;

  /// 点击添加项目按钮时的回调函数
  final VoidCallback onAddProject;

  const HomeAppBar({
    super.key,
    required this.onAddProject,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GitProvider>(
      builder: (context, gitProvider, _) {
        final hasProject = gitProvider.currentProject != null;

        return Container(
          decoration: kDebugLayout
              ? BoxDecoration(
                  border: Border.all(color: Colors.purple, width: 2),
                  color: Colors.purple.withOpacity(0.1),
                )
              : null,
          child: AppBar(
            title: const Text('GitOK'),
            actions: [
              if (hasProject) ...[
                const SizedBox(width: 16),
                SizedBox(
                  width: 200,
                  child: BranchSwitcher(
                    currentBranch: gitProvider.currentBranch,
                    branches: gitProvider.branches,
                    onBranchChanged: (branch) {
                      if (branch != null) {
                        gitProvider.switchBranch(branch);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
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
                    final result =
                        await Process.run('git', ['config', '--get', 'remote.origin.url'], workingDirectory: path);
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
                      // 通知 CommitHistory 刷新
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
              const SizedBox(width: 16),
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('添加项目'),
                onPressed: onAddProject,
              ),
              const SizedBox(width: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
