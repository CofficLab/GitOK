import 'package:flutter/material.dart';

/// macOS 风格的主题配置
class MacOSTheme {
  // 圆角大小
  static const double kBorderRadius = 6.0;
  static const double kSmallBorderRadius = 4.0;

  // 动画时长
  static const Duration kDefaultAnimationDuration = Duration(milliseconds: 200);
  static const Duration kFastAnimationDuration = Duration(milliseconds: 150);

  // 间距
  static const double kSpacing = 8.0;
  static const double kSmallSpacing = 4.0;

  // 获取亮色主题
  static ThemeData get lightTheme => _buildTheme(Brightness.light);

  // 获取暗色主题
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  // 构建主题
  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: brightness,
      ),
      useMaterial3: true,
      textTheme: TextTheme(
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black,
        ),
        titleMedium: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        titleSmall: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        bodyLarge: const TextStyle(fontSize: 14),
        bodyMedium: const TextStyle(fontSize: 13),
        bodySmall: const TextStyle(fontSize: 11),
        labelLarge: const TextStyle(fontSize: 13),
        labelMedium: const TextStyle(fontSize: 12),
        labelSmall: const TextStyle(fontSize: 11),
      ),
      visualDensity: VisualDensity.compact,
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kBorderRadius),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kSmallBorderRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kSmallBorderRadius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kSmallBorderRadius),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
      ),
      dividerTheme: const DividerThemeData(
        space: 1,
        thickness: 1,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStateProperty.all(8.0),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.dragged)) {
            return isDark ? Colors.white.withOpacity(0.38) : Colors.black.withOpacity(0.38);
          }
          if (states.contains(WidgetState.hovered)) {
            return isDark ? Colors.white.withOpacity(0.24) : Colors.black.withOpacity(0.24);
          }
          return isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.12);
        }),
        radius: const Radius.circular(4),
      ),
    );
  }
}
