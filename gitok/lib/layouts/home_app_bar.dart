import 'package:flutter/material.dart';
import 'package:gitok/widgets/buttons/git_action_buttons.dart';
import 'package:provider/provider.dart';
import 'package:gitok/providers/git_provider.dart';
import 'package:gitok/widgets/buttons/branch_switch_button.dart';

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

  const HomeAppBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GitProvider>(builder: (context, gitProvider, _) {
      final hasProject = gitProvider.currentProject != null;
      final isValidGitRepo = hasProject && gitProvider.currentProject!.isGitRepository;

      return Container(
        decoration: kDebugLayout
            ? BoxDecoration(
                border: Border.all(color: Colors.purple, width: 2),
                color: Colors.purple.withOpacity(0.1),
              )
            : null,
        child: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          actions: [
            if (hasProject && isValidGitRepo) ...[              
              const SizedBox(width: 16),
              const BranchSwitchButton(),
              const SizedBox(width: 16),
              const GitActionButtons(),
              const SizedBox(width: 16),
            ] else if (hasProject) ...[              
              const SizedBox(width: 16),
              const Text('当前项目不是有效的 Git 仓库'),
              const SizedBox(width: 16),
            ],
          ],
        ),
      );
    });
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
