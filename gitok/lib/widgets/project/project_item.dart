/// 项目列表项组件
///
/// 用于显示单个Git项目的信息，包括：
/// - 项目名称和路径
/// - 收藏状态标记
/// - 移除项目按钮
/// 支持点击选择和各种交互操作
import 'package:flutter/material.dart';
import 'package:gitok/models/git_project.dart';
import 'package:gitok/services/project_storage_service.dart';

class ProjectItem extends StatelessWidget {
  /// 是否启用调试模式以突出显示布局边界
  static const bool kDebugLayout = true;

  /// 项目数据
  final GitProject project;

  /// 项目是否被选中
  final bool isSelected;

  /// 点击项目时的回调
  final VoidCallback? onTap;

  /// 项目更新后的回调
  final VoidCallback? onProjectUpdated;

  /// 项目存储服务
  final ProjectStorageService _storageService;

  ProjectItem({
    super.key,
    required this.project,
    this.isSelected = false,
    this.onTap,
    this.onProjectUpdated,
  }) : _storageService = ProjectStorageService();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: kDebugLayout
          ? BoxDecoration(
              border: Border.all(color: Colors.blue, width: 1),
              color: Colors.blue.withOpacity(0.05),
            )
          : null,
      child: ListTile(
        leading: const Icon(Icons.folder),
        title: Text(project.name),
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
                onProjectUpdated?.call();
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
                          onProjectUpdated?.call();
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
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
        selected: isSelected,
        onTap: onTap,
      ),
    );
  }
}
