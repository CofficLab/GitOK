/// 更新对话框 - 显示更新信息和进度
///
/// 这个组件负责向用户展示更新相关的信息，包括：
/// - 新版本号和发布说明
/// - 下载进度条
/// - 更新操作按钮
///
/// 就像一个热情的导游 🧭，带领用户完成更新之旅！

import 'package:flutter/material.dart';
import 'package:gitok/services/update_service.dart';
import 'package:intl/intl.dart';

class UpdateDialog extends StatefulWidget {
  final UpdateService updateService;
  final UpdateInfo updateInfo;

  const UpdateDialog({
    Key? key,
    required this.updateService,
    required this.updateInfo,
  }) : super(key: key);

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  late UpdateService _updateService;
  bool _isDownloading = false;
  bool _isDownloaded = false;
  double _progress = 0.0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _updateService = widget.updateService;
    _updateService.addListener(_updateListener);
  }

  @override
  void dispose() {
    _updateService.removeListener(_updateListener);
    super.dispose();
  }

  void _updateListener() {
    if (mounted) {
      setState(() {
        _isDownloading = _updateService.status == UpdateStatus.downloading;
        _isDownloaded = _updateService.status == UpdateStatus.downloaded;
        _progress = _updateService.downloadProgress;

        if (_updateService.status == UpdateStatus.error) {
          _errorMessage = _updateService.errorMessage;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.system_update, color: theme.primaryColor),
          const SizedBox(width: 8),
          Text('发现新版本 ${widget.updateInfo.version}'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('发布时间: ${dateFormat.format(widget.updateInfo.releaseDate)}'),
            const SizedBox(height: 16),
            Text(
              '更新内容:',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                child: Text(
                  widget.updateInfo.releaseNotes.isEmpty ? '暂无更新说明' : widget.updateInfo.releaseNotes,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isDownloading || _progress > 0)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '下载进度: ${(_progress * 100).toStringAsFixed(1)}%',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: _progress),
                  const SizedBox(height: 16),
                ],
              ),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: theme.colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('稍后更新'),
        ),
        if (!_isDownloading && !_isDownloaded)
          ElevatedButton(
            onPressed: () async {
              try {
                await _updateService.downloadUpdate();
              } catch (e) {
                if (mounted) {
                  setState(() {
                    _errorMessage = e.toString();
                  });
                }
              }
            },
            child: const Text('下载更新'),
          ),
        if (_isDownloaded)
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _updateService.installUpdate();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: const Text('立即安装'),
          ),
      ],
    );
  }
}

/// 更新提示组件 - 显示在应用底部的更新通知条
class UpdateNotificationBar extends StatelessWidget {
  final UpdateService updateService;
  final VoidCallback onCheckNow;

  const UpdateNotificationBar({
    Key? key,
    required this.updateService,
    required this.onCheckNow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.primaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.system_update,
            color: theme.colorScheme.onPrimaryContainer,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            '发现新版本 ${updateService.updateInfo?.version}',
            style: TextStyle(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onPrimaryContainer,
            ),
            child: const Text('忽略'),
          ),
          ElevatedButton(
            onPressed: onCheckNow,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.onPrimaryContainer,
              foregroundColor: theme.colorScheme.primaryContainer,
            ),
            child: const Text('查看详情'),
          ),
        ],
      ),
    );
  }
}
