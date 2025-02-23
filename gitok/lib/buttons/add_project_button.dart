import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:gitok/providers/git_provider.dart';
import 'package:gitok/services/project_storage_service.dart';
import 'package:gitok/services/git_service.dart';
import 'package:gitok/models/git_project.dart';
import 'dart:io';

/// 添加项目按钮组件
class AddProjectButton extends StatelessWidget {
  final ProjectStorageService _storageService = ProjectStorageService();
  final GitService _gitService = GitService();

  AddProjectButton({super.key});

  Future<void> _addProject(BuildContext context) async {
    final result = await FilePicker.platform.getDirectoryPath();

    if (result != null) {
      if (await _gitService.isGitRepository(result)) {
        final projects = await _storageService.loadProjects();
        if (projects.any((p) => p.path == result)) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('该项目已在列表中')),
          );
          return;
        }

        final project = GitProject(
          name: result.split(Platform.pathSeparator).last,
          path: result,
          lastOpened: DateTime.now(),
        );

        await _storageService.addProject(project);
        if (context.mounted) {
          context.read<GitProvider>().notifyProjectsChanged();
        }
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('所选目录不是Git仓库')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.add),
      tooltip: '添加项目',
      onPressed: () => _addProject(context),
    );
  }
}
