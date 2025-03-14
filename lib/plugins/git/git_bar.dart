import 'package:flutter/material.dart';
import 'package:gitok/plugins/git/buttons/git_action_buttons.dart';
import 'package:provider/provider.dart';
import 'package:gitok/plugins/git/git_provider.dart';
import 'package:gitok/plugins/git/buttons/branch_switch_button.dart';

class GitBar extends StatelessWidget implements PreferredSizeWidget {
  const GitBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GitProvider>(builder: (context, gitProvider, _) {
      final hasProject = gitProvider.currentProject != null;
      final isValidGitRepo = hasProject && gitProvider.currentProject!.isGitRepository;

      return Row(
        children: [
          if (hasProject && isValidGitRepo) ...[
            const SizedBox(width: 16),
            const SizedBox(width: 16),
            const GitActionButtons(),
            const SizedBox(width: 16),
            const BranchSwitchButton(),
          ] else if (hasProject) ...[
            const SizedBox(width: 16),
            const Text('当前项目不是有效的 Git 仓库'),
            const SizedBox(width: 16),
          ],
        ],
      );
    });
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
