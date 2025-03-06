import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:gitok/core/models/app_icon_config.dart';
import 'package:gitok/core/services/icon_service.dart';

class IconPreview extends StatelessWidget {
  final AppIconConfig config;
  final double size;
  final String platform;
  final IconService _iconService = IconService();

  IconPreview({
    super.key,
    required this.config,
    required this.size,
    required this.platform,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(platform),
        const SizedBox(height: 8),
        FutureBuilder<ui.Image>(
          future: _generatePreview(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                width: size,
                height: size,
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return SizedBox(
                width: size,
                height: size,
                child: Center(child: Text('预览失败: ${snapshot.error}')),
              );
            }

            return CustomPaint(
              size: Size(size, size),
              painter: IconPainter(snapshot.data!),
            );
          },
        ),
      ],
    );
  }

  Future<ui.Image> _generatePreview() async {
    if (!File(config.imagePath).existsSync()) {
      throw Exception('源图片不存在');
    }

    return _iconService.processIcon(
      await _iconService.loadImage(config.imagePath),
      size.toInt(),
      config,
    );
  }
}

class IconPainter extends CustomPainter {
  final ui.Image image;

  IconPainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant IconPainter oldDelegate) {
    return oldDelegate.image != image;
  }
}
