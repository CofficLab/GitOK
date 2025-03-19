import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gitok/core/channels/channels.dart';
import 'package:gitok/utils/logger.dart';

/// 伙伴提供者
///
/// 负责管理与被覆盖应用的交互，包括：
/// 1. 跟踪被覆盖的应用信息
/// 2. 提供状态变化通知
/// 3. 管理应用切换状态
class CompanionProvider extends ChangeNotifier {
  static const String _tag = 'CompanionProvider';
  static CompanionProvider? _instance;

  /// 获取单例实例
  factory CompanionProvider() {
    _instance ??= CompanionProvider._();
    Logger.debug(_tag, '获取单例实例');
    return _instance!;
  }

  CompanionProvider._() {
    Logger.debug(_tag, '创建单例实例');
  }

  /// 被覆盖的应用名称
  String? _overlaidAppName;
  String? get overlaidAppName => _overlaidAppName;

  /// 初始化
  Future<void> initialize() async {
    Logger.info(_tag, '正在初始化...');

    try {
      // 设置方法调用处理器
      WindowChannel.instance.setMethodCallHandler(_handleMethodCall);
      Logger.info(_tag, '初始化完成');
    } catch (e) {
      Logger.error(_tag, '初始化失败', e);
    }
  }

  /// 处理来自原生端的方法调用
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    Logger.info(_tag, '收到方法调用 - ${call.method}');

    switch (call.method) {
      case 'updateOverlaidApp':
        final Map? appInfo = call.arguments;
        _overlaidAppName = appInfo?['name'] as String?;
        Logger.info(_tag, '更新被覆盖的应用: $_overlaidAppName');
        notifyListeners();
        break;
    }
  }

  @override
  void dispose() {
    Logger.debug(_tag, '正在释放资源...');
    WindowChannel.instance.setMethodCallHandler(null);
    super.dispose();
  }
}
