import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import '../contract/plugin_protocol.dart';
import 'search_box.dart';
import 'error_panel.dart';
import 'action_list.dart';
import 'plugin_status_bar.dart';
import 'package:provider/provider.dart';
import 'package:gitok/core/providers/window_state_provider.dart';
import 'package:gitok/utils/logger.dart';
import 'package:gitok/core/providers/plugin_manager_provider.dart';

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
/// 5. 响应窗口状态变化
/// 6. 窗口拖动支持：
///    - 在顶部添加了 20px 高的 DragToMoveArea
///    - 用户可以通过拖动此区域来移动窗口
///    - 这是必需的，因为整个界面都被 Flutter 接管
/// 7. 窗口视觉效果：
///    - 使用透明背景配合原生的毛玻璃效果
///    - Scaffold 和容器都需要设置透明背景
///    - 与 MainFlutterWindow.swift 中的 NSVisualEffectView 配合工作
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  List<PluginAction> _actions = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _selectedIndex = -1; // 当前选中的动作索引
  bool _lastFocusState = false; // 记录上一次的焦点状态

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // 组件初始化时触发一次搜索
    _onSearchChanged();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 获取当前焦点状态
    final hasFocus = context.read<WindowStateProvider>().hasFocus;

    // 只在焦点状态发生变化，且获得焦点时触发搜索
    if (hasFocus && !_lastFocusState) {
      Logger.debug('HomeScreen', '窗口获得焦点，刷新搜索结果');
      _onSearchChanged();
    }

    // 更新上一次的焦点状态
    _lastFocusState = hasFocus;
  }

  @override
  Widget build(BuildContext context) {
    // 监听窗口状态变化，但只用于UI更新
    final windowState = context.watch<WindowStateProvider>();

    return KeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKeyEvent: (event) => _handleKeyEvent(event),
      child: Scaffold(
        backgroundColor: Colors.transparent, // 设置 Scaffold 背景为透明
        body: Container(
          color: Colors.transparent, // 确保容器也是透明的
          child: Column(
            children: [
              // 当窗口失去焦点时，显示半透明遮罩
              if (!windowState.hasFocus)
                Container(
                  color: Colors.black.withAlpha(25),
                  width: double.infinity,
                  height: 2,
                ),
              Expanded(
                child: Stack(
                  children: [
                    // 主要内容
                    _buildMainContent(),

                    // 当窗口隐藏时，显示动画效果
                    if (!windowState.isVisible)
                      const Center(
                        child: Text(
                          '窗口已最小化到托盘',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onSearchChanged() async {
    final keyword = _searchController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final pluginManager = context.read<PluginManagerProvider>();
      final actions = await pluginManager.search(keyword);

      setState(() {
        _actions = actions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '搜索出错：$e';
        _isLoading = false;
      });
    }
  }

  Future<void> _executeAction(PluginAction action) async {
    try {
      final pluginManager = context.read<PluginManagerProvider>();
      await pluginManager.executeAction(action, context);
    } catch (e) {
      setState(() {
        _errorMessage = '执行动作失败：$e';
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
          await _executeAction(_actions[_selectedIndex]);
        }
        break;
    }
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        Expanded(
          child: Container(
            color: Colors.transparent,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // 搜索框和拖动区域的行
                Row(
                  children: [
                    // 搜索框占据大部分空间
                    Expanded(
                      child: SearchBox(
                        controller: _searchController,
                        autofocus: true,
                      ),
                    ),
                    // 拖动区域
                    const SizedBox(width: 8), // 间距
                    const DragToMoveArea(
                      child: Icon(
                        Icons.drag_indicator,
                        color: Colors.grey,
                        size: 24,
                      ),
                    ),
                  ],
                ),
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
                  child: Container(
                    color: Colors.transparent,
                    child: ActionList(
                      isLoading: _isLoading,
                      actions: _actions,
                      searchKeyword: _searchController.text,
                      onActionSelected: _executeAction,
                      selectedIndex: _selectedIndex,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // 插件状态栏
        PluginStatusBar(
          plugins: context.watch<PluginManagerProvider>().plugins,
        ),
      ],
    );
  }
}
