import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gitok/plugins/git/git_project.dart';

class ProjectStorageService {
  static const String _projectsKey = 'git_projects';
  static final ProjectStorageService _instance = ProjectStorageService._internal();

  factory ProjectStorageService() => _instance;
  ProjectStorageService._internal();

  Future<List<GitProject>> loadProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final projectsJson = prefs.getStringList(_projectsKey) ?? [];

    return projectsJson.map((json) => GitProject.fromJson(jsonDecode(json))).toList();
  }

  Future<void> saveProjects(List<GitProject> projects) async {
    final prefs = await SharedPreferences.getInstance();
    final projectsJson = projects.map((project) => jsonEncode(project.toJson())).toList();

    await prefs.setStringList(_projectsKey, projectsJson);
  }

  Future<void> addProject(GitProject project) async {
    final projects = await loadProjects();
    projects.add(project);
    await saveProjects(projects);
  }

  Future<void> removeProject(String path) async {
    final projects = await loadProjects();
    projects.removeWhere((project) => project.path == path);
    await saveProjects(projects);
  }

  Future<void> updateProject(GitProject project) async {
    final projects = await loadProjects();
    final index = projects.indexWhere((p) => p.path == project.path);
    if (index != -1) {
      projects[index] = project;
      await saveProjects(projects);
    }
  }

  /// 初始化服务
  Future<void> init() async {
    // 初始化 SharedPreferences 等资源
  }

  /// 释放资源
  Future<void> dispose() async {
    // 清理资源
  }
}
