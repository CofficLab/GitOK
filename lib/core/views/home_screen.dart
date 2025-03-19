import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../contract/plugin_protocol.dart';
import '../managers/plugin_manager.dart';
import 'search_box.dart';
import 'error_panel.dart';
import 'action_list.dart';
import 'plugin_status_bar.dart';

/// 主页面
///
/// 展示搜索框和动作列表，是用户与插件交互的主要界面。
/// 功能：
/// 1. 响应用户输入，实时显示搜索结果
/// 2. 展示插件返回的动作列表
/// 3. 处理动作的点击事件
/// 4. 支持键盘导航：
///    - 上下键选择动作
///    - 回车键执行选中的动作
class HomeScreen extends StatefulWidget {
  final AppPluginManager pluginManager;

  const HomeScreen({
    super.key,
    required this.pluginManager,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  List<PluginAction> _actions = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _selectedIndex = -1; // 当前选中的动作索引

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onSearchChanged() async {
    final keyword = _searchController.text;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedIndex = -1; // 重置选中项
    });

    try {
      final actions = await widget.pluginManager.queryAll(keyword);
      if (!mounted) return;

      setState(() {
        _actions = actions;
        _isLoading = false;
        // 如果有结果，默认选中第一项
        _selectedIndex = actions.isEmpty ? -1 : 0;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _actions = [];
        _isLoading = false;
        _errorMessage = e.toString();
        _selectedIndex = -1;
      });
    }
  }

  Future<void> _onActionSelected(PluginAction action) async {
    try {
      await widget.pluginManager.executeAction(action.id, context);

      // 清除可能存在的错误消息
      setState(() {
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  /// 处理键盘事件
  Future<void> _handleKeyEvent(KeyEvent event) async {
    // 只处理按键按下事件
    if (event is! KeyDownEvent) return;

    // 如果没有动作或正在加载，不处理键盘事件
    if (_actions.isEmpty || _isLoading) return;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        setState(() {
          // 向上选择，如果已经是第一项则循环到最后一项
          _selectedIndex = (_selectedIndex <= 0) ? _actions.length - 1 : _selectedIndex - 1;
        });
        break;

      case LogicalKeyboardKey.arrowDown:
        setState(() {
          // 向下选择，如果已经是最后一项则循环到第一项
          _selectedIndex = (_selectedIndex >= _actions.length - 1) ? 0 : _selectedIndex + 1;
        });
        break;

      case LogicalKeyboardKey.enter:
        // 如果有选中项，执行选中的动作
        if (_selectedIndex >= 0 && _selectedIndex < _actions.length) {
          await _onActionSelected(_actions[_selectedIndex]);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKeyEvent: (event) => _handleKeyEvent(event),
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // 搜索框
                    SearchBox(controller: _searchController),
                    const SizedBox(height: 16),

                    // 错误提示面板
                    if (_errorMessage != null) ...[
                      ErrorPanel(
                        errorMessage: _errorMessage!,
                        onClose: () => setState(() => _errorMessage = null),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 动作列表
                    Expanded(
                      child: ActionList(
                        isLoading: _isLoading,
                        actions: _actions,
                        searchKeyword: _searchController.text,
                        onActionSelected: _onActionSelected,
                        selectedIndex: _selectedIndex, // 传递选中项索引
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 插件状态栏
            PluginStatusBar(
              plugins: widget.pluginManager.plugins,
            ),
          ],
        ),
      ),
    );
  }
}
