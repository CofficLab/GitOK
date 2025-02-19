import 'package:flutter/material.dart';

/// A widget that allows switching between Git branches.
class BranchSwitcher extends StatelessWidget {
  final String currentBranch;
  final List<String> branches;
  final Function(String?) onBranchChanged;

  const BranchSwitcher({
    super.key,
    required this.currentBranch,
    required this.branches,
    required this.onBranchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('切换分支: '),
        DropdownButton<String>(
          value: currentBranch,
          items: branches.map((branch) {
            return DropdownMenuItem(
              value: branch,
              child: Text(branch),
            );
          }).toList(),
          onChanged: onBranchChanged,
        ),
      ],
    );
  }
}
