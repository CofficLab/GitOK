# GitOK 项目目录结构规范 📚

## 项目简介 🎯

GitOK 是一个类似 macOS Spotlight 的快速启动工具，采用插件化架构设计：
- 核心模块负责界面展示和插件调度
- 插件模块负责具体功能实现

## 目录结构 🌲

```
lib/
├── core/                   # 核心模块
│   ├── contract/          # 接口协议定义
│   │   ├── plugin.dart           # 插件基础接口
│   │   ├── plugin_action.dart    # 插件动作数据结构
│   │   ├── plugin_manager.dart   # 插件管理器接口
│   │   └── plugin_protocol.dart  # 协议统一导出
│   │
│   ├── managers/          # 各类管理器
│   │   ├── plugin_manager.dart   # 插件管理器实现
│   │   ├── window_manager.dart   # 窗口管理
│   │   ├── hotkey_manager.dart   # 快捷键管理
│   │   └── tray_manager.dart     # 系统托盘管理
│   │
│   ├── layouts/           # 界面布局组件
│   │   └── home_screen.dart      # 主界面
│   │
│   ├── theme/            # 主题相关
│   │   └── macos_theme.dart      # macOS风格主题
│   │
│   └── widgets/          # 共享组件
│       └── search_bar.dart       # 搜索栏组件
│
├── plugins/              # 插件模块
│   └── app_launcher/    # 应用启动器插件
│       └── app_launcher_plugin.dart
│
└── utils/               # 工具类
    └── logger.dart      # 日志工具
```

## 命名规范 📝

1. 文件命名：
   - 使用小写字母和下划线
   - 文件名应清晰描述其内容
   - 例如：`home_screen.dart`, `plugin_manager.dart`

2. 目录命名：
   - 使用小写字母
   - 用简短但有意义的名称
   - 例如：`core`, `plugins`, `utils`

## 目录职责 🎯

### core/ 核心模块
- `contract/`: 定义插件系统的接口协议
- `managers/`: 存放各类管理器实现
- `layouts/`: 存放页面级组件
- `widgets/`: 存放可复用的UI组件
- `theme/`: 存放主题相关配置

### plugins/ 插件模块
- 每个插件一个独立目录
- 插件目录下包含插件实现和相关资源
- 遵循核心模块定义的插件协议

### utils/ 工具模块
- 存放全局共享的工具类
- 工具类应该是无状态的
- 提供通用功能支持

## 开发规范 💻

1. 单一职责：
   - 每个文件只包含一个主要的类/功能
   - 保持类的功能单一和清晰

2. 代码组织：
   - 相关的功能放在同一目录下
   - 共享组件放在 `widgets` 目录
   - 页面级组件放在 `layouts` 目录

3. 文档规范：
   - 每个文件都应有清晰的中文注释文档
   - 说明文件的主要功能和使用方式
   - 重要的方法需要添加注释说明

4. 插件开发：
   - 新插件创建独立目录
   - 实现 `Plugin` 接口
   - 遵循插件协议规范

## 构建发布 🚀

- 项目托管在 GitHub：https://github.com/CofficLab/GitOK
- 通过 GitHub Actions 自动构建和发布
- 构建配置文件：`.github/workflows/pre-release.yaml`

## 最佳实践 ✨

1. 保持目录结构清晰，避免过深的嵌套
2. 相关文件放在一起，便于维护
3. 遵循文件命名规范，保持一致性
4. 编写清晰的文档注释
5. 定期检查和优化目录结构 