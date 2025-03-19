/// 插件协议
///
/// 定义了内核和插件之间的交互接口。插件需要实现这个协议才能被内核加载和调用。
/// 主要包含：
/// 1. 插件基本信息
/// 2. 动作数据结构
/// 3. 插件响应方法
///
/// 这个文件作为协议的统一入口点，导出所有需要的类型。
library;

export 'plugin_action.dart';
export 'plugin.dart';
export 'plugin_manager.dart';
