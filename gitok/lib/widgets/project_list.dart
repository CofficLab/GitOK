import 'package:flutter/material.dart';
import 'package:gitok/models/git_project.dart';
import 'package:gitok/services/git_service.dart';
import 'package:gitok/services/project_storage_service.dart';

class ProjectList extends StatefulWidget {
  final Function(GitProject)? onProjectSelected;

  const ProjectList({
    super.key,
    this.onProjectSelected,
  });

  @override
  State<ProjectList> createState() => ProjectListState();
}

class ProjectListState extends State<ProjectList> {
  final List<GitProject> _projects = [];
  final GitService _gitService = GitService();
  final ProjectStorageService _storageService = ProjectStorageService();
  String _searchQuery = '';
  GitProject? _selectedProject;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  void refreshProjects() {
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final projects = await _storageService.loadProjects();
    if (mounted) {
      setState(() {
        _projects.clear();
        _projects.addAll(projects);
      });
    }
  }

  List<GitProject> get _filteredProjects {
    if (_searchQuery.isEmpty) {
      return _projects;
    }
    return _projects.where((project) {
      return project.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          project.path.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SearchBar(
            hintText: '搜索项目...',
            leading: const Icon(Icons.search),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        Expanded(
          child: _filteredProjects.isEmpty
              ? const Center(
                  child: Text(
                    '没有找到项目\n点击右上角的"添加项目"按钮来添加',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredProjects.length,
                  itemBuilder: (context, index) {
                    final project = _filteredProjects[index];
                    return ListTile(
                      leading: const Icon(Icons.folder),
                      title: Text(project.name),
                      subtitle: Text(
                        project.path,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              project.isFavorite ? Icons.star : Icons.star_border,
                              color: project.isFavorite ? Colors.amber : null,
                            ),
                            onPressed: () async {
                              final updatedProject = GitProject(
                                name: project.name,
                                path: project.path,
                                description: project.description,
                                lastOpened: project.lastOpened,
                                isFavorite: !project.isFavorite,
                              );
                              await _storageService.updateProject(updatedProject);
                              await _loadProjects();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('确认移除'),
                                  content: Text('确定要从列表中移除 ${project.name} 吗？\n(不会删除磁盘上的文件)'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('取消'),
                                    ),
                                    FilledButton(
                                      onPressed: () async {
                                        await _storageService.removeProject(project.path);
                                        await _loadProjects();
                                        if (!mounted) return;
                                        Navigator.pop(context);
                                      },
                                      child: const Text('移除'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      selected: widget.onProjectSelected != null && _selectedProject?.path == project.path,
                      onTap: () {
                        widget.onProjectSelected?.call(project);
                        setState(() {
                          _selectedProject = project;
                        });
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
