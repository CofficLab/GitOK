import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../contract/plugin_protocol.dart';
import 'search_box.dart';
import 'error_panel.dart';
import 'action_list.dart';

/// 主页面
///
/// 展示搜索框和动作列表，是用户与插件交互的主要界面。
/// 功能：
/// 1. 响应用户输入，实时显示搜索结果
/// 2. 展示插件返回的动作列表
/// 3. 处理动作的点击事件
/// 4. 支持回车键快速执行第一个动作
class HomeScreen extends StatefulWidget {
  final PluginManager pluginManager;

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
      _errorMessage = null; // 清除之前的错误
    });

    try {
      final actions = await widget.pluginManager.queryAll(keyword);
      if (!mounted) return;

      setState(() {
        _actions = actions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _actions = [];
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _onActionSelected(PluginAction action) async {
    try {
      // 查找对应的插件
      final plugin = widget.pluginManager.plugins.firstWhere(
        (p) => action.id.startsWith(p.id),
        orElse: () => throw Exception('找不到处理该动作的插件'),
      );

      // 执行动作
      await plugin.onAction(action.id, context);

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
  Future<void> _handleKeyEvent(RawKeyEvent event) async {
    // 只处理按键按下事件
    if (event is! RawKeyDownEvent) return;

    // 如果按下回车键且有可用的动作
    if (event.logicalKey == LogicalKeyboardKey.enter && _actions.isNotEmpty && !_isLoading) {
      // 执行第一个动作
      await _onActionSelected(_actions.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKey: (event) => _handleKeyEvent(event),
      child: Scaffold(
        body: Padding(
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
