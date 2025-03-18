import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gitok/plugins/launcher/launcher_provider.dart';

/// 软件启动器视图
class LauncherView extends StatelessWidget {
  const LauncherView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<LauncherProvider>(
      builder: (context, provider, child) {
        // 如果正在加载，显示加载指示器
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // 如果没有找到应用，显示空状态
        if (provider.filteredApps.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.search_off,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  '找不到匹配的应用',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  '尝试使用不同的搜索关键词',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // 显示应用列表
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: '搜索应用...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: provider.filterApps,
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemCount: provider.filteredApps.length,
                itemBuilder: (context, index) {
                  final app = provider.filteredApps[index];
                  return _AppTile(app: app);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 应用图标及名称小部件
class _AppTile extends StatelessWidget {
  final AppItem app;

  const _AppTile({Key? key, required this.app}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.read<LauncherProvider>().launchApp(app).then((success) {
          if (!success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('无法启动应用: ${app.name}')),
            );
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            app.icon,
            size: 48,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 8),
          Text(
            app.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          // 路径显示（可选）
          Text(
            app.path.split('/').last,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
