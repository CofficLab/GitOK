import 'package:flutter/material.dart';
import 'package:gitok/layouts/project_list_layout.dart';
import 'package:gitok/layouts/project_detail_layout.dart';
import 'package:gitok/widgets/project/project_list.dart';
import 'package:gitok/models/git_project.dart';
import 'package:reorderable_grid/reorderable_grid.dart';

/// GitOK应用程序的主体布局组件。
///
/// 提供一个分屏布局：
/// - 左侧固定宽度的项目列表
/// - 右侧自适应宽度的项目详情面板
///
/// 该组件负责处理主界面的整体布局结构，包括分割线的显示。
class HomeBodyLayout extends StatefulWidget {
  /// 是否启用调试模式以突出显示布局边界
  static const bool kDebugLayout = false;

  /// 项目列表的全局键，用于访问列表状态
  final GlobalKey<ProjectListState> projectListKey;

  const HomeBodyLayout({
    super.key,
    required this.projectListKey,
  });

  @override
  State<HomeBodyLayout> createState() => _HomeBodyLayoutState();
}

class _HomeBodyLayoutState extends State<HomeBodyLayout> {
  double _leftPanelWidth = 300; // 初始宽度
  static const double _minWidth = 200; // 最小宽度
  static const double _maxWidth = 500; // 最大宽度

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: HomeBodyLayout.kDebugLayout
          ? BoxDecoration(
              border: Border.all(color: Colors.red, width: 2),
              color: Colors.yellow.withOpacity(0.1),
            )
          : null,
      child: Row(
        children: [
          SizedBox(
            width: _leftPanelWidth,
            child: ProjectListLayout(listKey: widget.projectListKey),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.resizeColumn,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _leftPanelWidth += details.delta.dx;
                  // 限制宽度范围
                  _leftPanelWidth = _leftPanelWidth.clamp(_minWidth, _maxWidth);
                });
              },
              child: Container(
                width: 2,
                height: double.infinity,
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          const Expanded(child: ProjectDetailLayout()),
        ],
      ),
    );
  }
}
