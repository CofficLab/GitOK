import 'package:flutter/material.dart';
import 'package:gitok/widgets/git/branch_switcher.dart';
import 'package:provider/provider.dart';
import 'package:gitok/providers/git_provider.dart';

/// 分支切换按钮组件
///
/// 封装了分支切换的功能，包括：
/// - 显示当前分支
/// - 提供分支切换的下拉菜单
/// - 处理分支切换的回调
class BranchSwitchButton extends StatelessWidget {
  const BranchSwitchButton({super.key});

  @override
  Widget build(BuildContext context) {
    final gitProvider = Provider.of<GitProvider>(context);
    return SizedBox(
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
    );
  }
}