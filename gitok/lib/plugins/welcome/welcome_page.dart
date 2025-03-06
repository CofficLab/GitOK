/// 欢迎界面
///
/// 展示应用的使用教程和快捷键设置
/// 包含：
/// - 应用介绍
/// - 基本使用教程
/// - 快捷键设置
/// - 开始使用按钮

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gitok/plugins/config/config_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            children: [
              _buildWelcomePage(),
              _buildTutorialPage(),
              _buildHotkeySettingPage(),
            ],
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _totalPages,
                    (index) => _buildPageIndicator(index == _currentPage),
                  ),
                ),
                const SizedBox(height: 20),
                _buildNavigationButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.celebration, size: 100, color: Colors.blue),
          const SizedBox(height: 30),
          Text(
            '欢迎使用 GitOK',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          const Text(
            '让Git仓库管理变得简单高效',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialPage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '基本使用教程',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 40),
              _buildFeatureItem(
                icon: Icons.folder_open,
                title: '添加仓库',
                description: '点击左上角的"+"按钮添加Git仓库',
              ),
              _buildFeatureItem(
                icon: Icons.sync,
                title: '同步状态',
                description: '自动监测仓库变化，实时显示状态',
              ),
              _buildFeatureItem(
                icon: Icons.keyboard,
                title: '快捷操作',
                description: '使用全局快捷键快速访问应用',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHotkeySettingPage() {
    return const Padding(
      padding: EdgeInsets.all(32.0),
      child: ConfigPage(isEmbedded: true),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: 400,
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 60,
            alignment: Alignment.center,
            child: Icon(icon, size: 40, color: Colors.blue),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? Colors.blue : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_currentPage > 0)
          TextButton(
            onPressed: () {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: const Text('上一步'),
          ),
        const SizedBox(width: 20),
        ElevatedButton(
          onPressed: () {
            if (_currentPage < _totalPages - 1) {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            } else {
              _completeOnboarding();
            }
          },
          child: Text(_currentPage < _totalPages - 1 ? '下一步' : '开始使用'),
        ),
      ],
    );
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_welcome', true);
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }
}
