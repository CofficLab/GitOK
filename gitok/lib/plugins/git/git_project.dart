import 'dart:io';

class GitProject {
  final String name;
  final String path;
  final String? description;
  final DateTime lastOpened;
  final bool isFavorite;
  late final bool isGitRepository;

  GitProject({
    required this.name,
    required this.path,
    this.description,
    required this.lastOpened,
    this.isFavorite = false,
  }) {
    // 检查项目目录下是否存在 .git 文件夹
    final gitDir = Directory('$path/.git');
    isGitRepository = gitDir.existsSync();
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      'description': description,
      'lastOpened': lastOpened.toIso8601String(),
      'isFavorite': isFavorite,
    };
  }

  factory GitProject.fromJson(Map<String, dynamic> json) {
    return GitProject(
      name: json['name'],
      path: json['path'],
      description: json['description'],
      lastOpened: DateTime.parse(json['lastOpened']),
      isFavorite: json['isFavorite'] ?? false,
    );
  }
}
