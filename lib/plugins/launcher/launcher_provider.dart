import 'dart:io';
import 'package:flutter/material.dart';

/// 软件列表项目模型
class AppItem {
  final String name;
  final String path;
  final IconData icon;

  AppItem({required this.name, required this.path, this.icon = Icons.laptop});
}

/// 软件启动器状态管理
class LauncherProvider extends ChangeNotifier {
  final List<AppItem> _apps = [];
  List<AppItem> _filteredApps = [];
  bool _isLoading = false;

  /// 获取过滤后的应用列表
  List<AppItem> get filteredApps => _filteredApps;

  /// 是否正在加载
  bool get isLoading => _isLoading;

  LauncherProvider() {
    _loadApps();
  }

  /// 加载系统应用列表
  Future<void> _loadApps() async {
    _isLoading = true;
    notifyListeners();

    // 这里是模拟数据，实际实现需要根据不同平台获取已安装的应用
    // 在实际实现中，可以使用平台特定的方法获取应用列表
    _apps.addAll([
      AppItem(name: 'Chrome', path: '/Applications/Google Chrome.app', icon: Icons.web),
      AppItem(name: 'VSCode', path: '/Applications/Visual Studio Code.app', icon: Icons.code),
      AppItem(name: 'Terminal', path: '/Applications/Utilities/Terminal.app', icon: Icons.terminal),
      AppItem(name: 'Finder', path: '/System/Library/CoreServices/Finder.app', icon: Icons.folder),
      AppItem(name: 'Safari', path: '/Applications/Safari.app', icon: Icons.public),
      AppItem(name: 'Mail', path: '/Applications/Mail.app', icon: Icons.mail),
      AppItem(name: 'Photos', path: '/Applications/Photos.app', icon: Icons.photo),
      AppItem(name: 'Music', path: '/Applications/Music.app', icon: Icons.music_note),
    ]);

    _filteredApps = List.from(_apps);

    _isLoading = false;
    notifyListeners();
  }

  /// 根据查询过滤应用列表
  void filterApps(String query) {
    if (query.isEmpty) {
      _filteredApps = List.from(_apps);
    } else {
      _filteredApps = _apps.where((app) => app.name.toLowerCase().contains(query.toLowerCase())).toList();
    }
    notifyListeners();
  }

  /// 启动应用
  Future<bool> launchApp(AppItem app) async {
    try {
      // 简单的实现，实际应该根据平台使用不同的启动方法
      if (Platform.isMacOS) {
        await Process.run('open', [app.path]);
        return true;
      } else if (Platform.isWindows) {
        await Process.run('start', [app.path]);
        return true;
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [app.path]);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('启动应用失败: $e');
      return false;
    }
  }
}
