import 'package:flutter/material.dart';

/// 应用程序状态管理器
///
/// 负责管理应用程序的全局状态，包括：
/// - 当前选中的标签页
/// - 可用的标签页列表
class AppProvider extends ChangeNotifier {
  /// 当前选中的标签页索引
  int _currentTabIndex = 0;

  /// 获取当前选中的标签页索引
  int get currentTabIndex => _currentTabIndex;

  /// 设置当前选中的标签页索引
  set currentTabIndex(int index) {
    if (index != _currentTabIndex && index >= 0 && index < tabs.length) {
      _currentTabIndex = index;
      notifyListeners();
    }
  }

  /// 可用的标签页列表
  final List<Tab> tabs = const [
    Tab(text: 'Git管理'),
    Tab(text: 'APP图标'),
    Tab(text: '宣传图'),
    Tab(text: 'API测试'),
  ];
}
