/// GitOK - 窗口状态提供者
///
/// 负责管理和提供窗口的状态信息，包括：
/// - 窗口是否可见
/// - 窗口是否获得焦点
/// - 窗口是否最大化
///
/// 使用方式：
/// ```dart
/// // 获取窗口状态
/// final windowState = context.watch<WindowStateProvider>();
///
/// // 使用窗口状态
/// if (windowState.isVisible) {
///   // 当窗口可见时的逻辑
/// }
/// ```
library;

import 'package:flutter/foundation.dart';

/// 窗口状态提供者
class WindowStateProvider extends ChangeNotifier {
  static final WindowStateProvider _instance = WindowStateProvider._internal();
  factory WindowStateProvider() => _instance;
  WindowStateProvider._internal();

  bool _isVisible = true;
  bool _hasFocus = true;
  bool _isMaximized = false;

  /// 窗口是否可见
  bool get isVisible => _isVisible;

  /// 窗口是否获得焦点
  bool get hasFocus => _hasFocus;

  /// 窗口是否最大化
  bool get isMaximized => _isMaximized;

  /// 更新窗口可见状态
  void setVisibility(bool isVisible) {
    if (_isVisible != isVisible) {
      _isVisible = isVisible;
      notifyListeners();
    }
  }

  /// 更新窗口焦点状态
  void setFocus(bool hasFocus) {
    if (_hasFocus != hasFocus) {
      _hasFocus = hasFocus;
      notifyListeners();
    }
  }

  /// 更新窗口最大化状态
  void setMaximized(bool isMaximized) {
    if (_isMaximized != isMaximized) {
      _isMaximized = isMaximized;
      notifyListeners();
    }
  }
}
