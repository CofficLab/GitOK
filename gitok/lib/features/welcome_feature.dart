import 'package:flutter/material.dart';
import 'package:gitok/pages/welcome_page.dart';

/// 欢迎功能模块
///
/// 包装了欢迎页面，使其符合功能模块的标准接口
class WelcomeFeature extends StatelessWidget {
  const WelcomeFeature({super.key});

  @override
  Widget build(BuildContext context) {
    return const WelcomePage();
  }
}
