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
import 'package:gitok/utils/logger.dart';

/// 窗口状态提供者
class WindowStateProvider extends ChangeNotifier {
  static final WindowStateProvider _instance = WindowStateProvider._internal();
  factory WindowStateProvider() => _instance;
  WindowStateProvider._internal() {
    Logger.info('WindowStateProvider', '创建窗口状态提供者');
  }

  static const String _tag = 'WindowStateProvider';

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
    Logger.debug(_tag, '尝试设置窗口可见性: ${isVisible ? '显示' : '隐藏'}, 当前状态: ${_isVisible ? '显示' : '隐藏'}');
    if (_isVisible != isVisible) {
      _isVisible = isVisible;
      Logger.info(_tag, '窗口可见性变更: ${isVisible ? '显示' : '隐藏'}');
      notifyListeners();
    } else {
      Logger.debug(_tag, '窗口可见性未变化，跳过更新');
    }
  }

  /// 更新窗口焦点状态
  void setFocus(bool hasFocus) {
    if (_hasFocus != hasFocus) {
      _hasFocus = hasFocus;
      Logger.info(_tag, '窗口焦点变更: ${hasFocus ? '获得焦点' : '失去焦点'}');
      notifyListeners();
    }
  }

  /// 更新窗口最大化状态
  void setMaximized(bool isMaximized) {
    if (_isMaximized != isMaximized) {
      _isMaximized = isMaximized;
      Logger.info(_tag, '窗口最大化状态变更: ${isMaximized ? '最大化' : '还原'}');
      notifyListeners();
    }
  }
}
