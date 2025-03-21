# @cofficlab/command-key-listener

macOS系统Command键（⌘）双击事件监听器。

## 功能介绍

- 监听macOS系统Command键（⌘）的双击事件
- 使用原生模块实现，性能高效稳定
- 提供简单的事件接口，易于集成
- 支持自定义双击间隔和触发行为

## 安装

```bash
# 使用npm
npm install @cofficlab/command-key-listener

# 使用yarn
yarn add @cofficlab/command-key-listener

# 使用pnpm
pnpm add @cofficlab/command-key-listener
```

## 系统要求

- **操作系统**: 仅支持macOS系统
- **Node.js**: >= 14.0.0
- **构建工具**: Xcode命令行工具（用于编译原生模块）

## 基本用法

```typescript
import { CommandKeyListener } from '@cofficlab/command-key-listener';

// 创建监听器实例
const listener = new CommandKeyListener();

// 监听Command键双击事件
listener.on('command-double-press', () => {
  console.log('Command键被双击了!');
  // 在这里执行您想要的操作
});

// 启动监听器（返回Promise）
listener.start().then(success => {
  if (success) {
    console.log('监听器已启动');
  } else {
    console.error('监听器启动失败');
  }
});

// ... 应用其他逻辑 ...

// 停止监听（不再需要时）
listener.stop();
```

## API参考

### `CommandKeyListener` 类

#### 构造函数

```typescript
new CommandKeyListener()
```

创建一个新的Command键双击监听器实例。

#### 方法

##### `start(): Promise<boolean>`

启动监听器。返回一个Promise，解析为布尔值表示是否成功启动。

##### `stop(): boolean`

停止监听器。返回布尔值表示是否成功停止。

##### `isListening(): boolean`

获取监听器的当前状态。返回布尔值表示是否正在监听。

#### 事件

##### `command-double-press`

当检测到Command键双击时触发。

```typescript
listener.on('command-double-press', () => {
  // 处理双击事件
});
```

## 注意事项

1. **平台限制**: 此包仅在macOS系统上可用，在其他平台上将不起作用但不会导致错误。

2. **权限要求**: 使用此监听器时，您的应用可能需要辅助功能（Accessibility）权限。首次使用时，macOS可能会提示用户授予权限。

3. **应用打包**: 在使用Electron或其他工具打包应用时，请确保正确包含原生模块文件。

4. **可能的冲突**: 此监听器使用系统级事件监听，可能与其他使用相同技术的应用产生冲突。

## 故障排除

### 监听器无法启动

- 检查您是否在macOS系统上运行
- 确保已授予应用辅助功能权限
- 检查控制台是否有错误信息

### 编译错误

如果在安装过程中遇到编译错误：

- 确保已安装Xcode命令行工具：`xcode-select --install`
- 确保Node.js版本兼容
- 尝试使用`npm rebuild`重建原生模块

## 许可证

MIT

## 贡献

欢迎提交Issue和Pull Request。 