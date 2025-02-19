import 'package:flutter/material.dart';
import 'package:gitok/widgets/project_list.dart' show ProjectList, ProjectListState;
import 'package:gitok/widgets/project_detail_panel.dart';
import 'package:gitok/models/git_project.dart';
import 'package:file_picker/file_picker.dart';
import 'package:gitok/services/project_storage_service.dart';
import 'package:gitok/services/git_service.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GitProject? _selectedProject;
  final ProjectStorageService _storageService = ProjectStorageService();
  final GlobalKey<ProjectListState> _projectListKey = GlobalKey<ProjectListState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GitOK'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('添加项目'),
              onPressed: _addProject,
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          Container(
            width: 300,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: ProjectList(
              key: _projectListKey,
              onProjectSelected: (project) {
                setState(() {
                  _selectedProject = project;
                });
              },
            ),
          ),
          Expanded(
            child: ProjectDetailPanel(project: _selectedProject),
          ),
        ],
      ),
    );
  }

  Future<void> _addProject() async {
    final result = await FilePicker.platform.getDirectoryPath();

    if (result != null) {
      final gitService = GitService();
      if (await gitService.isGitRepository(result)) {
        final projects = await _storageService.loadProjects();
        if (projects.any((p) => p.path == result)) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('该项目已在列表中'),
            ),
          );
          return;
        }

        final project = GitProject(
          name: result.split(Platform.pathSeparator).last,
          path: result,
          lastOpened: DateTime.now(),
        );

        await _storageService.addProject(project);
        _projectListKey.currentState?.refreshProjects();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('所选目录不是Git仓库'),
          ),
        );
      }
    }
  }
}
