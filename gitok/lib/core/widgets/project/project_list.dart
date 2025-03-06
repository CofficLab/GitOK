/// 项目列表组件
///
/// 这个组件用于显示所有Git项目的列表，支持以下功能：
/// - 显示项目名称和路径
/// - 搜索过滤项目
/// - 收藏/取消收藏项目
/// - 从列表中移除项目
/// - 选择项目进行操作
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gitok/core/models/git_project.dart';
import 'package:gitok/core/services/project_storage_service.dart';
import 'package:gitok/plugins/git/git_provider.dart';
import 'package:gitok/core/widgets/project/project_item.dart';

/// 项目列表组件
class ProjectList extends StatefulWidget {
  const ProjectList({super.key});

  @override
  State<ProjectList> createState() => ProjectListState();
}

/// 项目列表的状态类
class ProjectListState extends State<ProjectList> {
  /// 存储所有项目的列表
  final List<GitProject> _projects = [];

  /// 项目存储服务实例，用于处理项目的持久化存储
  final ProjectStorageService _storageService = ProjectStorageService();

  /// 搜索查询字符串
  final String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProjects();
    // 监听 GitProvider 的变化
    Future.microtask(() {
      context.read<GitProvider>().addListener(_onGitProviderChanged);
    });
  }

  /// 刷新项目列表
  ///
  /// 重新加载所有项目的数据
  void refreshProjects() {
    _loadProjects();
  }

  /// 从存储服务加载项目列表
  ///
  /// 异步加载所有保存的项目，并更新状态
  Future<void> _loadProjects() async {
    final projects = await _storageService.loadProjects();
    if (mounted) {
      setState(() {
        _projects.clear();
        _projects.addAll(projects);
      });
    }
  }

  /// 获取过滤后的项目列表
  ///
  /// 根据搜索查询字符串过滤项目列表
  /// 如果搜索字符串为空，返回所有项目
  /// 否则返回名称或路径包含搜索字符串的项目
  List<GitProject> get _filteredProjects {
    if (_searchQuery.isEmpty) {
      return _projects;
    }
    return _projects.where((project) {
      return project.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          project.path.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  /// 构建项目列表界面
  ///
  /// 界面包含以下部分：
  /// - 顶部搜索栏：用于过滤项目
  /// - 项目列表：
  ///   * 显示项目名称和路径
  ///   * 收藏按钮：可以标记/取消标记收藏
  ///   * 移除按钮：可以从列表中移除项目
  ///   * 点击项目可以选中并触发回调
  /// - 如果没有项目，显示提示信息
  @override
  void dispose() {
    // 移除监听器
    context.read<GitProvider>().removeListener(_onGitProviderChanged);
    super.dispose();
  }

  /// 当 GitProvider 发生变化时刷新项目列表
  void _onGitProviderChanged() {
    _loadProjects();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GitProvider>(
      builder: (context, gitProvider, child) => Column(
        children: [
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
                      return ProjectItem(
                        project: project,
                        isSelected: gitProvider.currentProject?.path == project.path,
                        onTap: () => gitProvider.setCurrentProject(project),
                        onProjectUpdated: _loadProjects,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
