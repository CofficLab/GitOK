class GitProject {
  final String name;
  final String path;
  final String? description;
  final DateTime lastOpened;
  final bool isFavorite;

  GitProject({
    required this.name,
    required this.path,
    this.description,
    required this.lastOpened,
    this.isFavorite = false,
  });

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
