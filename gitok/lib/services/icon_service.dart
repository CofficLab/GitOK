import 'dart:io';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:gitok/models/app_icon_config.dart';

class IconService {
  static final IconService _instance = IconService._internal();
  factory IconService() => _instance;
  IconService._internal();

  Future<void> saveIconConfig(String projectPath, AppIconConfig config) async {
    final configDir = Directory(path.join(projectPath, '.gitok', 'icons'));
    await configDir.create(recursive: true);

    final json = config.toJson();

    final file = File(path.join(configDir.path, '${config.name}.json'));
    await file.writeAsString(jsonEncode(json));
  }

  Future<List<AppIconConfig>> loadIconConfigs(String projectPath) async {
    final configDir = Directory(path.join(projectPath, '.gitok', 'icons'));
    if (!await configDir.exists()) {
      return [];
    }

    final configs = <AppIconConfig>[];
    await for (final file in configDir.list()) {
      if (file.path.endsWith('.json')) {
        try {
          final content = await File(file.path).readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;

          if (json['name'] == null || json['imagePath'] == null || json['lastModified'] == null) {
            continue;
          }

          configs.add(AppIconConfig.fromJson(json));
        } catch (e) {
          continue;
        }
      }
    }
    return configs;
  }

  Future<void> generateIcons(String projectPath, AppIconConfig config) async {
    // iOS图标尺寸
    final iosSizes = {
      20: [2, 3], // Notifications
      29: [2, 3], // Settings
      40: [2, 3], // Spotlight
      60: [2, 3], // App icon
      76: [1, 2], // iPad
      83.5: [2], // iPad Pro
      1024: [1], // App Store
    };

    final sourceImage = await _loadImage(config.imagePath);
    final outputDir = Directory(path.join(projectPath, 'ios_icons'));
    await outputDir.create(recursive: true);

    for (final size in iosSizes.entries) {
      for (final scale in size.value) {
        final targetSize = size.key * scale;
        final iconImage = await _processIcon(
          sourceImage,
          targetSize.toInt(),
          config,
        );

        final fileName = 'Icon-${size.key.toInt()}@${scale}x.png';
        final outputPath = path.join(outputDir.path, fileName);
        await _saveImage(iconImage, outputPath);
      }
    }
  }

  Future<ui.Image> _loadImage(String imagePath) async {
    final file = File(imagePath);
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<ui.Image> _processIcon(
    ui.Image sourceImage,
    int targetSize,
    AppIconConfig config,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(targetSize.toDouble(), targetSize.toDouble());
    final paint = Paint()..isAntiAlias = true;

    // 绘制背景
    paint.color = config.backgroundColor;
    canvas.drawRect(Offset.zero & size, paint);

    // 计算图标绘制区域
    final iconSize = size.width - (config.padding * 2);
    final rect = Rect.fromLTWH(
      config.padding,
      config.padding,
      iconSize,
      iconSize,
    );

    // 绘制图标
    paint.color = Colors.black;
    canvas.drawImageRect(
      sourceImage,
      Rect.fromLTWH(0, 0, sourceImage.width.toDouble(), sourceImage.height.toDouble()),
      rect,
      paint,
    );

    // 绘制边框
    if (config.hasBorder) {
      paint.color = config.borderColor;
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = config.borderWidth;
      canvas.drawRect(rect, paint);
    }

    final picture = recorder.endRecording();
    return picture.toImage(targetSize, targetSize);
  }

  Future<void> _saveImage(ui.Image image, String path) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();
    final file = File(path);
    await file.writeAsBytes(buffer);
  }

  Future<ui.Image> processIcon(ui.Image sourceImage, int targetSize, AppIconConfig config) {
    return _processIcon(sourceImage, targetSize, config);
  }

  Future<ui.Image> loadImage(String imagePath) {
    return _loadImage(imagePath);
  }
}
