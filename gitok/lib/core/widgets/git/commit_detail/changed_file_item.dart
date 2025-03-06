import 'package:flutter/material.dart';
import 'package:gitok/plugins/git/file_status.dart';
import 'package:provider/provider.dart';
import 'package:gitok/plugins/git/git_provider.dart';

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
      child: GestureDetector(
        onSecondaryTapUp: (details) {
          _showContextMenu(context, details.globalPosition);
        },
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
      ),
    );
  }

  void _showContextMenu(BuildContext context, Offset position) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect positionRect = RelativeRect.fromRect(
      Rect.fromPoints(position, position),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: positionRect,
      items: [
        PopupMenuItem(
          child: const Text('取消更改'),
          onTap: () {
            final gitProvider = context.read<GitProvider>();
            gitProvider.discardFileChanges(file.path);
          },
        ),
      ],
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
