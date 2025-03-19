import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gitok/adapter/vscode.dart';
import '../channels/channels.dart';
import '../../utils/logger.dart';
import 'package:gitok/adapter/cursor.dart';

/// 伙伴提供者
///
/// 负责管理与被覆盖应用的交互，包括：
/// 1. 跟踪被覆盖的应用信息
/// 2. 提供状态变化通知
/// 3. 管理应用切换状态
/// 4. 管理不同应用的工作区信息
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

  /// 被覆盖的应用包名
  String? _overlaidAppBundleId;
  String? get overlaidAppBundleId => _overlaidAppBundleId;

  /// 被覆盖的应用进程ID
  int? _overlaidAppProcessId;
  int? get overlaidAppProcessId => _overlaidAppProcessId;

  /// 当前工作区路径
  String? _workspace;
  String? get workspace => _workspace;

  /// 支持的应用包名到工作区获取函数的映射
  final Map<String, Future<String?> Function()> _workspaceProviders = {
    'com.microsoft.VSCode': () => VSCode.getActiveWorkspace(),
    'com.todesktop.230313mzl4w4u92': () => Cursor.getActiveWorkspace(),
    // 未来可以在这里添加更多应用的工作区获取函数
    // 例如:
    // 'com.jetbrains.intellij': () => IntelliJChannel.instance.getActiveWorkspace(),
    // 'com.sublimetext.4': () => SublimeTextChannel.instance.getActiveWorkspace(),
  };

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
        final Map<String, dynamic>? appInfo =
            call.arguments != null ? Map<String, dynamic>.from(call.arguments as Map) : null;
        await updateOverlaidApp(appInfo);
        break;
    }
  }

  /// 更新被覆盖的应用信息
  Future<void> updateOverlaidApp(Map<String, dynamic>? appInfo) async {
    if (appInfo == null) {
      _overlaidAppName = null;
      _overlaidAppBundleId = null;
      _overlaidAppProcessId = null;
      _workspace = null;
      notifyListeners();
      return;
    }

    _overlaidAppName = appInfo['name'] as String?;
    _overlaidAppBundleId = appInfo['bundleId'] as String?;
    _overlaidAppProcessId = appInfo['processId'] as int?;

    // 尝试获取工作区信息
    if (_overlaidAppBundleId != null) {
      final workspaceProvider = _workspaceProviders[_overlaidAppBundleId];
      if (workspaceProvider != null) {
        try {
          _workspace = await workspaceProvider();
          Logger.info(_tag, '更新工作区: $_workspace (来自: $_overlaidAppName)');
        } catch (e) {
          Logger.error(_tag, '获取工作区失败: $_overlaidAppName', e);
          _workspace = null;
        }
      } else {
        Logger.debug(_tag, '应用 $_overlaidAppName ($_overlaidAppBundleId) 暂不支持工作区获取');
        _workspace = null;
      }
    } else {
      _workspace = null;
    }

    notifyListeners();
  }

  /// 注册新的工作区提供者
  void registerWorkspaceProvider(String bundleId, Future<String?> Function() provider) {
    _workspaceProviders[bundleId] = provider;
    Logger.info(_tag, '注册工作区提供者: $bundleId');
  }

  @override
  void dispose() {
    Logger.debug(_tag, '正在释放资源...');
    WindowChannel.instance.setMethodCallHandler(null);
    super.dispose();
  }
}
