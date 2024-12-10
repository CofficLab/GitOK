import 'dart:io';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:gitok/models/promo_config.dart';

class PromoService {
  static final PromoService _instance = PromoService._internal();
  factory PromoService() => _instance;
  PromoService._internal();

  Future<void> savePromoConfig(String projectPath, PromoConfig config) async {
    final configDir = Directory(path.join(projectPath, '.gitok', 'promos'));
    await configDir.create(recursive: true);

    final file = File(path.join(configDir.path, '${config.name}.json'));
    await file.writeAsString(jsonEncode(config.toJson()));
  }

  Future<List<PromoConfig>> loadPromoConfigs(String projectPath) async {
    final configDir = Directory(path.join(projectPath, '.gitok', 'promos'));
    if (!await configDir.exists()) {
      return [];
    }

    final configs = <PromoConfig>[];
    await for (final file in configDir.list()) {
      if (file.path.endsWith('.json')) {
        try {
          final content = await File(file.path).readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          configs.add(PromoConfig.fromJson(json));
        } catch (e) {
          print('Error loading promo config: $e');
        }
      }
    }
    return configs;
  }

  Future<void> exportPromo(String outputPath, PromoConfig config) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // 绘制背景
    final backgroundImage = await _loadImage(config.backgroundImage);
    canvas.drawImageRect(
      backgroundImage,
      Rect.fromLTWH(0, 0, backgroundImage.width.toDouble(), backgroundImage.height.toDouble()),
      Rect.fromLTWH(0, 0, 1242, 2208), // iPhone 6.5" 尺寸
      Paint(),
    );

    // 绘制元素
    for (final element in config.elements) {
      switch (element.type) {
        case 'text':
          final textPainter = TextPainter(
            text: TextSpan(
              text: element.properties['text'] as String,
              style: TextStyle(
                fontSize: element.properties['fontSize'] as double,
                color: Color(element.properties['color'] as int),
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();

          canvas.save();
          canvas.translate(element.x, element.y);
          canvas.rotate(element.rotation);
          textPainter.paint(canvas, Offset.zero);
          canvas.restore();
          break;

        case 'image':
          final image = await _loadImage(element.properties['imagePath'] as String);
          canvas.save();
          canvas.translate(element.x, element.y);
          canvas.rotate(element.rotation);
          canvas.drawImageRect(
            image,
            Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
            Rect.fromLTWH(0, 0, element.width, element.height),
            Paint(),
          );
          canvas.restore();
          break;
      }
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(1242, 2208);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    // 直接保存到指定目录
    final file = File(path.join(outputPath, 'promo.png'));
    await file.writeAsBytes(buffer);
  }

  Future<ui.Image> _loadImage(String imagePath) async {
    final file = File(imagePath);
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}
