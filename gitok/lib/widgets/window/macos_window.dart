import 'package:flutter/material.dart';

/// macOS 风格的窗口装饰器
class MacOSWindow extends StatelessWidget {
  final Widget child;

  const MacOSWindow({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 标题栏
        Container(
          height: 28,
          color: Theme.of(context).colorScheme.surface,
          child: Row(
            children: [
              const SizedBox(width: 70), // 留出空间给系统按钮
              Expanded(
                child: Center(
                  child: Text(
                    'GitOK',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
            ],
          ),
        ),
        // 主内容
        Expanded(child: child),
      ],
    );
  }
}
