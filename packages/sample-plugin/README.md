# GitOK 示例插件

这是一个用于演示如何开发 GitOK 插件的示例项目。

## 功能

这个示例插件提供了以下功能：

1. **打招呼** - 一个简单的问候动作，展示基本的动作执行方式
2. **当前时间** - 显示当前时间的自定义视图，演示嵌入式视图
3. **计算器** - 一个简单的计算器，演示独立窗口视图

## 安装

在 GitOK 应用启动后，此示例插件会自动复制到开发插件目录中，你可以通过搜索框直接使用它提供的功能。

## 开发自己的插件

如果你想基于这个示例开发自己的 GitOK 插件，请遵循以下步骤：

1. 复制示例插件目录作为起点

   ```bash
   # 示例插件位于用户数据目录的开发插件文件夹中
   # macOS: ~/Library/Application Support/buddy/plugins/dev/example-plugin
   # Windows: %APPDATA%\buddy\plugins\dev\example-plugin
   # Linux: ~/.config/buddy/plugins/dev/example-plugin
   ```

2. 修改 `package.json` 中的插件信息

   ```json
   {
     "name": "your-plugin-id",
     "version": "1.0.0",
     "description": "你的插件描述",
     "main": "index.js"
   }
   ```

3. 修改 `index.js` 中的插件ID和其他信息

   ```javascript
   const PLUGIN_ID = 'your-plugin-id';

   const plugin = {
     id: PLUGIN_ID,
     name: '你的插件名称',
     description: '你的插件描述',
     // ...
   };
   ```

4. 自定义插件动作

   - 在 `getActions` 函数中定义你的动作
   - 在 `executeAction` 函数中实现动作逻辑
   - 如有必要，在 `views` 目录中创建自定义视图HTML文件

5. 测试你的插件
   - 确保你的插件在正确的开发目录中
   - 重启 GitOK 应用
   - 在搜索框中查找你的插件动作

## 插件开发指南

### 插件接口

每个 GitOK 插件必须实现以下接口：

```typescript
interface Plugin {
  id: string; // 插件唯一ID
  name: string; // 插件名称
  description: string; // 插件描述
  version: string; // 插件版本
  author: string; // 插件作者

  getActions(keyword?: string): Promise<Action[]>; // 获取插件动作
  executeAction(action: Action): Promise<any>; // 执行动作
  getViewContent?(viewPath: string): Promise<string>; // 获取视图HTML (可选)
}
```

### 动作定义

每个动作应包含以下字段：

```typescript
interface Action {
  id: string; // 动作唯一ID (格式: 'plugin-id:action-name')
  title: string; // 动作标题
  description: string; // 动作描述
  icon: string; // 动作图标 (可使用Emoji)
  plugin: string; // 插件ID
  viewPath?: string; // 视图路径 (可选)
  viewMode?: 'embedded' | 'window'; // 视图模式 (可选)
}
```

### 视图开发

HTML视图文件应遵循以下最佳实践：

1. 使用标准HTML5结构
2. 确保样式隔离，避免影响主应用
3. 使用内联CSS样式
4. 使用内联JavaScript，不要依赖外部库
5. 避免使用敏感API，如`eval`

有关更多信息，请参考完整的 GitOK 插件开发文档。
