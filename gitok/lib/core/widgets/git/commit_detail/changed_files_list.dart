import 'package:flutter/material.dart';
import 'package:gitok/core/models/file_status.dart';
import 'package:gitok/core/widgets/git/commit_detail/changed_file_item.dart';

/// 变更文件列表组件
class ChangedFilesList extends StatelessWidget {
  final List<FileStatus> files;
  final String? selectedPath;
  final Function(FileStatus) onFileSelected;

  const ChangedFilesList({
    super.key,
    required this.files,
    required this.selectedPath,
    required this.onFileSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('变更文件:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: 8),
            Text('(${files.length})', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              return ChangedFileItem(
                file: file,
                isSelected: selectedPath == file.path,
                onTap: () => onFileSelected(file),
              );
            },
          ),
        ),
      ],
    );
  }
}
