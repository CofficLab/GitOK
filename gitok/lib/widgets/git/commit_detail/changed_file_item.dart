import 'package:flutter/material.dart';
import 'package:gitok/models/file_status.dart';

/// Git变更文件列表项组件
class ChangedFileItem extends StatelessWidget {
  final FileStatus file;
  final bool isSelected;
  final VoidCallback onTap;

  const ChangedFileItem({
    super.key,
    required this.file,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
        ),
        child: ListTile(
          leading: _getStatusIcon(file.status),
          title: Text(
            file.path,
            style: TextStyle(
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            _getStatusText(file.status),
            style: TextStyle(
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7)
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          selected: isSelected,
          onTap: onTap,
          dense: true,
          hoverColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
        ),
      ),
    );
  }

  Icon _getStatusIcon(String status) {
    switch (status) {
      case 'M':
        return const Icon(Icons.edit, color: Colors.orange);
      case 'A':
        return const Icon(Icons.add_circle, color: Colors.green);
      case 'D':
        return const Icon(Icons.remove_circle, color: Colors.red);
      default:
        return const Icon(Icons.help);
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'M':
        return '已修改';
      case 'A':
        return '新增';
      case 'D':
        return '已删除';
      default:
        return '未知状态';
    }
  }
}
