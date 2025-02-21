import 'package:flutter/material.dart';
import 'package:gitok/layouts/home_app_bar.dart';
import 'package:gitok/layouts/project_detail_layout.dart';
import 'package:gitok/widgets/project/project_list.dart' show ProjectListState;
import 'package:gitok/models/git_project.dart';
import 'package:file_picker/file_picker.dart';
import 'package:gitok/services/project_storage_service.dart';
import 'package:gitok/services/git_service.dart';
import 'dart:io';
import 'package:gitok/layouts/sidebar.dart';

/// GitOK应用程序的主屏幕。
/// 提供一个分屏界面，左侧是项目列表，右侧是项目详情。
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// HomeScreen 组件的状态类。
///
/// 该类负责管理：
/// - 项目选择状态
/// - 项目存储操作
/// - 添加新的Git项目到应用程序
class _HomeScreenState extends State<HomeScreen> {
  /// 用于持久化和加载项目数据的服务
  final ProjectStorageService _storageService = ProjectStorageService();

  /// 用于访问ProjectList状态以刷新列表的全局键
  final GlobalKey<ProjectListState> _projectListKey = GlobalKey<ProjectListState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 侧边栏
          Container(
            width: 250, // 固定宽度
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1.0,
                ),
              ),
            ),
            child: const AppDrawer(),
          ),
          // 主内容区
          Expanded(
            child: Scaffold(
              appBar: HomeAppBar(onAddProject: _addProject),
              body: const ProjectDetailLayout(),
            ),
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
