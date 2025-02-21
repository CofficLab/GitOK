import 'package:flutter/material.dart';
import 'package:gitok/widgets/buttons/git_action_buttons.dart';
import 'package:provider/provider.dart';
import 'package:gitok/providers/git_provider.dart';
import 'package:gitok/widgets/git/branch_switcher.dart';

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
            backgroundColor: Theme.of(context).colorScheme.surface,
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
                const GitActionButtons(),
                const SizedBox(width: 16),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
