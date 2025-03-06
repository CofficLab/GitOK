import 'package:flutter/material.dart';

class AppIconConfig {
  final String name;
  final String imagePath;
  final double cornerRadius;
  final Color backgroundColor;
  final bool hasBorder;
  final Color borderColor;
  final double borderWidth;
  final double padding;
  final DateTime lastModified;

  AppIconConfig({
    required this.name,
    required this.imagePath,
    this.cornerRadius = 0,
    this.backgroundColor = Colors.white,
    this.hasBorder = false,
    this.borderColor = Colors.black,
    this.borderWidth = 1,
    this.padding = 0,
    required this.lastModified,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'imagePath': imagePath,
      'cornerRadius': cornerRadius,
      'backgroundColor': backgroundColor.value,
      'hasBorder': hasBorder,
      'borderColor': borderColor.value,
      'borderWidth': borderWidth,
      'padding': padding,
      'lastModified': lastModified.toIso8601String(),
    };
  }

  factory AppIconConfig.fromJson(Map<String, dynamic> json) {
    return AppIconConfig(
      name: json['name'] as String,
      imagePath: json['imagePath'] as String,
      cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? 0,
      backgroundColor: Color(json['backgroundColor'] as int? ?? Colors.white.value),
      hasBorder: json['hasBorder'] as bool? ?? false,
      borderColor: Color(json['borderColor'] as int? ?? Colors.black.value),
      borderWidth: (json['borderWidth'] as num?)?.toDouble() ?? 1,
      padding: (json['padding'] as num?)?.toDouble() ?? 0,
      lastModified: DateTime.parse(json['lastModified'] as String),
    );
  }
}
