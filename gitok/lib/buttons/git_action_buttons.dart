import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gitok/providers/git_provider.dart';
import 'package:gitok/buttons/vscode_button.dart';
import 'package:gitok/buttons/browser_button.dart';
import 'package:gitok/buttons/finder_button.dart';
import 'package:gitok/buttons/terminal_button.dart';
import 'package:gitok/buttons/pull_button.dart';
import 'package:gitok/buttons/push_button.dart';

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

    return const Row(
      children: [
        VSCodeButton(),
        BrowserButton(),
        FinderButton(),
        TerminalButton(),
        PullButton(),
        PushButton(),
      ],
    );
  }
}
