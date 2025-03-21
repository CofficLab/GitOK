# GitOK 插件系统 API 参考

本文档提供了 GitOK 插件系统的详细 API 参考，包括插件接口、动作规范和视图内容要求。

## 插件接口

插件必须实现以下接口才能被正确加载和使用。

### 基本接口

```typescript
interface Plugin {
  id: string; // 插件唯一标识符
  name: string; // 插件名称
  description: string; // 插件描述
  version: string; // 插件版本
  author: string; // 插件作者

  // 必需方法
  getActions(keyword: string): Promise<PluginAction[]>; // 获取插件提供的动作
  executeAction(action: PluginAction): Promise<any>; // 执行特定动作

  // 可选方法
  getViewContent?(viewPath: string): Promise<string>; // 获取视图HTML内容
  initialize?(): Promise<void>; // 插件初始化
  destroy?(): Promise<void>; // 插件卸载清理
}
```

### PluginAction 接口

动作是插件提供的功能单元，由以下字段定义：

```typescript
interface PluginAction {
  id: string; // 动作唯一标识符，通常格式为 `pluginId:actionName`
  title: string; // 动作标题，显示在界面上
  description: string; // 动作描述，提供额外信息
  icon: string; // 动作图标，可以是 Unicode 字符或 URL
  plugin: string; // 所属插件 ID
  viewPath?: string; // 可选，动作视图路径
  keywords?: string[]; // 可选，额外关键词便于搜索
  disabled?: boolean; // 可选，是否禁用此动作
  category?: string; // 可选，动作分类
}
```

## 方法详解

### getActions(keyword: string): Promise<PluginAction[]>

返回插件提供的动作列表，可根据关键词过滤。

**参数：**

- `keyword` (string): 用户输入的搜索关键词

**返回值：**

- Promise<PluginAction[]>: 匹配的动作数组

**示例：**

```javascript
async getActions(keyword = '') {
  const actions = [
    {
      id: `${PLUGIN_ID}:hello`,
      title: '打招呼',
      description: '显示问候消息',
      icon: '👋',
      plugin: PLUGIN_ID,
    },
    // 更多动作...
  ];

  if (keyword) {
    const lowerKeyword = keyword.toLowerCase();
    return actions.filter(
      action =>
        action.title.toLowerCase().includes(lowerKeyword) ||
        action.description.toLowerCase().includes(lowerKeyword)
    );
  }

  return actions;
}
```

### executeAction(action: PluginAction): Promise<any>

执行特定动作并返回结果。

**参数：**

- `action` (PluginAction): 要执行的动作对象

**返回值：**

- Promise<any>: 动作执行结果，格式自定义

**示例：**

```javascript
async executeAction(action) {
  switch (action.id) {
    case `${PLUGIN_ID}:hello`:
      return { message: '你好，这是来自插件的问候！' };

    case `${PLUGIN_ID}:getData`:
      // 获取数据的逻辑
      const data = await fetchData();
      return { success: true, data };

    default:
      throw new Error(`未知的动作ID: ${action.id}`);
  }
}
```

### getViewContent(viewPath: string): Promise<string>

返回动作视图的 HTML 内容。

**参数：**

- `viewPath` (string): 视图文件路径，相对于插件根目录

**返回值：**

- Promise<string>: HTML 内容字符串

**示例：**

```javascript
async getViewContent(viewPath) {
  try {
    const filePath = path.join(__dirname, viewPath);
    if (!fs.existsSync(filePath)) {
      throw new Error(`视图文件不存在: ${filePath}`);
    }

    return fs.readFileSync(filePath, 'utf-8');
  } catch (error) {
    console.error(`获取视图内容失败:`, error);
    throw error;
  }
}
```

### initialize(): Promise<void>

插件初始化方法，在插件加载后调用。

**参数：** 无

**返回值：**

- Promise<void>: 完成初始化的 Promise

**示例：**

```javascript
async initialize() {
  // 加载配置
  this.config = await this.loadConfig();

  // 初始化资源
  await this.setupResources();

  console.log(`${this.name} 插件已初始化`);
}
```

### destroy(): Promise<void>

插件卸载清理方法，在插件卸载前调用。

**参数：** 无

**返回值：**

- Promise<void>: 完成清理的 Promise

**示例：**

```javascript
async destroy() {
  // 保存配置
  await this.saveConfig();

  // 释放资源
  await this.releaseResources();

  console.log(`${this.name} 插件已清理`);
}
```

## 视图 API

插件视图是使用 HTML、CSS 和 JavaScript 创建的自定义界面，在隔离的 iframe 中渲染。

### 视图沙箱限制

视图在沙箱环境中运行，受到以下限制：

- 默认情况下，无法访问主应用的 DOM
- 不能使用 `require()` 或导入 Node.js 模块
- 无法直接访问 Electron API

### 视图 HTML 结构要求

视图 HTML 应当是一个完整的 HTML 文档，包含以下基本结构：

```html
<!DOCTYPE html>
<html>
  <head>
    <title>动作标题</title>
    <style>
      /* 视图样式 */
    </style>
  </head>
  <body>
    <!-- 视图内容 -->
    <script>
      // 视图逻辑
    </script>
  </body>
</html>
```

### 视图最佳实践

1. **自适应布局**：使用响应式设计使视图适应不同大小
2. **使用沙箱友好的 API**：只使用浏览器标准 API
3. **错误处理**：在视图中捕获并显示错误
4. **加载状态**：提供加载和错误状态的视觉反馈

## 插件包结构

### package.json

插件的 `package.json` 必须包含以下字段：

```json
{
  "name": "gitok-my-plugin", // 插件名称
  "version": "1.0.0", // 版本号
  "description": "插件描述", // 描述
  "main": "index.js", // 入口文件
  "gitokPlugin": {
    // GitOK 插件信息
    "id": "my-plugin" // 插件 ID
  },
  "author": "作者名称", // 作者
  "license": "MIT" // 许可证
}
```

可选字段：

```json
{
  "gitokPlugin": {
    "id": "my-plugin",
    "minAppVersion": "1.0.0", // 最低 GitOK 版本
    "maxAppVersion": "2.0.0", // 最高 GitOK 版本
    "homepage": "https://example.com", // 插件主页
    "repository": "https://github.com/user/repo", // 代码仓库
    "tags": ["工具", "git"] // 插件标签
  }
}
```

## 错误处理

### 错误类型

在插件开发中，可能遇到以下类型的错误：

1. **加载错误**：插件无法加载，通常是结构或兼容性问题
2. **动作错误**：动作执行过程中的错误
3. **视图错误**：视图内容渲染错误

### 错误响应格式

当插件方法抛出错误时，应当提供清晰的错误信息：

```javascript
throw new Error(`操作失败: ${detailedReason}`);
```

系统也支持返回结构化错误对象：

```javascript
return {
  success: false,
  error: '操作失败',
  details: {
    code: 'FILE_NOT_FOUND',
    path: '/path/to/file',
  },
};
```

## 生命周期事件

如果插件实现了可选的生命周期方法，它们将在以下情况被调用：

- **initialize()**: 插件首次加载时
- **destroy()**: 插件被卸载或应用关闭时

## 调试与日志

推荐在插件中实现日志功能：

```javascript
const log = {
  info: function (message, ...args) {
    console.log(`[${PLUGIN_ID}] ${message}`, ...args);
  },
  error: function (message, ...args) {
    console.error(`[${PLUGIN_ID}] ${message}`, ...args);
  },
  debug: function (message, ...args) {
    console.log(`[${PLUGIN_ID}:调试] ${message}`, ...args);
  },
};
```

日志将显示在 GitOK 的开发者工具控制台中。

## 插件配置文件

建议保存插件配置的标准位置：

- **Windows**: `%APPDATA%\.gitok\plugins\{plugin-id}.json`
- **macOS**: `~/Library/Application Support/.gitok/plugins/{plugin-id}.json`
- **Linux**: `~/.config/.gitok/plugins/{plugin-id}.json`

使用下面的辅助代码获取跨平台配置路径：

```javascript
const { app } = require('electron');
const path = require('path');

const configDir = path.join(app.getPath('userData'), 'plugins');
const configFile = path.join(configDir, `${PLUGIN_ID}.json`);
```

## 安全注意事项

开发插件时，请注意以下安全最佳实践：

1. **验证输入**：不要信任动作参数，始终验证格式和范围
2. **限制权限**：只请求必要的系统访问权限
3. **安全执行命令**：在执行命令前验证命令字符串
4. **处理敏感数据**：不要在日志中输出敏感信息
5. **正确处理错误**：提供友好的错误信息但不泄露内部细节

## 未来 API（计划中）

以下是计划在未来版本中添加的 API：

1. **插件间通信 API**：允许插件之间交换数据和功能
2. **事件订阅 API**：监听应用事件并作出响应
3. **持久化存储 API**：统一的数据存储接口
4. **UI 组件库**：标准化视图 UI 组件
5. **权限系统**：细粒度的权限控制

## 完整示例

请参考 [示例插件解析](./05-example-plugin.md) 文档，其中包含了完整的示例插件代码和详细解析。

---

© 2023 CofficLab. 保留所有权利。
