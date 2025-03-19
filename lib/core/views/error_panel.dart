import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 错误面板组件
///
/// 用于显示错误信息的面板，支持：
/// 1. 错误信息展示
/// 2. 复制错误信息
/// 3. 关闭面板
/// 4. 自定义样式
class ErrorPanel extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onClose;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  const ErrorPanel({
    super.key,
    required this.errorMessage,
    required this.onClose,
    this.backgroundColor = const Color(0xFFFFEBEE), // Colors.red.shade50
    this.borderColor = const Color(0xFFFFCDD2), // Colors.red.shade200
    this.textColor = Colors.red,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: textColor),
              const SizedBox(width: 8),
              Text(
                '发生错误',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // 关闭按钮
              IconButton(
                icon: Icon(Icons.close, color: textColor),
                onPressed: onClose,
                tooltip: '关闭',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage,
            style: TextStyle(color: textColor),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.copy),
                label: const Text('复制错误信息'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: errorMessage));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('错误信息已复制到剪贴板'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
