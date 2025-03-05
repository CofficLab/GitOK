import 'package:flutter/material.dart';
import 'package:gitok/pages/config_page.dart';
import 'package:gitok/widgets/project/project_list.dart';
import 'package:gitok/buttons/add_project_button.dart';

class AppDrawer extends StatelessWidget {
  /// 是否启用调试模式以突出显示布局边界
  static const bool kDebugLayout = false;

  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 0),
      decoration: kDebugLayout
          ? BoxDecoration(
              border: Border.all(color: Colors.green, width: 2),
              color: Colors.green.withOpacity(0.1),
            )
          : null,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(
              top: 28, // 顶部边距
              bottom: 16, // 底部边距
              left: 12, // 左侧边距
              right: 12, // 右侧边距
            ),
            // decoration: BoxDecoration(
            //   color: Theme.of(context).primaryColor.withOpacity(0.1),
            // ),
            child: Row(
              children: [
                const Text(
                  'GitOK 🚀',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                AddProjectButton(),
              ],
            ),
          ),
          const Expanded(
            child: ProjectList(),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('设置'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ConfigPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('关于'),
            onTap: () {
              // 处理关于点击
            },
          ),
        ],
      ),
    );
  }
}
