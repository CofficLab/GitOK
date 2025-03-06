import 'package:flutter/material.dart';
import 'package:gitok/core/pages/config_page.dart';

/// 设置功能模块
///
/// 包装了设置页面，使其符合功能模块的标准接口
class ConfigFeature extends StatelessWidget {
  const ConfigFeature({super.key});

  @override
  Widget build(BuildContext context) {
    return const ConfigPage(isEmbedded: true);
  }
}
