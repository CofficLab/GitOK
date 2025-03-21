# 8. 插件开发指南

本指南将帮助您从零开始创建一个 Buddy 插件，包括设置开发环境、实现插件功能和发布插件。

## 开发环境准备

### 安装开发工具

开发 Buddy 插件需要以下工具：

- **Node.js** (v14 或更高版本)
- **npm** 或 **yarn** 包管理器
- **TypeScript** (推荐但不强制)
- **Visual Studio Code** (推荐编辑器)

### 插件模板

我们提供了插件开发模板，帮助您快速开始：

```bash
# 克隆插件模板仓库
git clone https://github.com/buddy-app/plugin-template.git my-plugin

# 进入项目目录
cd my-plugin

# 安装依赖
npm install
```

## 创建插件

### 项目结构

一个典型的 Buddy 插件项目结构如下：

```
my-plugin/
├── src/                      # 源代码目录
│   ├── index.ts              # 插件主文件
│   └── components/           # Vue 组件目录
│       ├── MainView.vue      # 主视图组件
│       └── SettingsView.vue  # 设置视图组件
├── assets/                   # 静态资源目录
│   └── icon.svg              # 插件图标
├── dist/                     # 构建输出目录
├── manifest.json             # 插件清单文件
├── package.json              # npm 配置文件
├── tsconfig.json             # TypeScript 配置
└── README.md                 # 插件说明文档
```

### 插件清单

首先，创建一个 `manifest.json` 文件，定义插件的基本信息：

```json
{
  "id": "my-awesome-plugin",
  "name": "我的插件",
  "version": "1.0.0",
  "description": "这是我的第一个 Buddy 插件",
  "author": "您的名字",
  "main": "dist/index.js",
  "engines": {
    "buddy": "^1.0.0"
  },
  "views": [
    {
      "id": "main-view",
      "name": "主视图",
      "component": "components/MainView.vue",
      "icon": "dashboard"
    },
    {
      "id": "settings-view",
      "name": "设置",
      "component": "components/SettingsView.vue",
      "icon": "settings"
    }
  ],
  "permissions": [
    "filesystem.read",
    "network.http"
  ]
}
```

### 插件主文件

创建插件主文件 `src/index.ts`：

```typescript
/**
 * 我的 Buddy 插件
 */
class MyPlugin {
  private logger: any;

  /**
   * 插件初始化
   */
  async initialize() {
    this.logger = console;
    this.logger.log('插件正在初始化...');
    
    // 初始化资源
    return true;
  }
  
  /**
   * 插件激活
   */
  async activate() {
    this.logger.log('插件已激活');
    
    // 注册菜单和命令
    this.registerCommands();
    
    return true;
  }
  
  /**
   * 插件停用
   */
  async deactivate() {
    this.logger.log('插件已停用');
    
    // 清理资源
    return true;
  }
  
  /**
   * 注册命令
   */
  private registerCommands() {
    // 例如，注册一个命令，显示一个对话框
    buddy.app.commands.register('my-plugin.showDialog', async () => {
      await buddy.ui.showMessage('你好，这是来自插件的消息！');
    });
  }
}

// 导出插件实例
export default new MyPlugin();
```

### 创建 Vue 组件

创建一个简单的 Vue 组件 `src/components/MainView.vue`：

```vue
<template>
  <div class="my-plugin-view">
    <h1>{{ title }}</h1>
    <p>{{ message }}</p>
    <button @click="handleClick" class="primary-button">点击我</button>
    <div v-if="result" class="result">{{ result }}</div>
  </div>
</template>

<script setup>
import { ref } from 'vue';

const title = ref('我的插件');
const message = ref('这是一个 Buddy 插件视图');
const result = ref('');

const handleClick = async () => {
  try {
    // 使用插件 API 来执行操作
    const response = await buddy.net.fetch('https://api.example.com/data');
    const data = await response.json();
    result.value = JSON.stringify(data, null, 2);
  } catch (error) {
    result.value = `错误: ${error.message}`;
  }
};
</script>

<style scoped>
.my-plugin-view {
  padding: 20px;
  font-family: system-ui, -apple-system, BlinkMacSystemFont, sans-serif;
}

h1 {
  color: #333;
  margin-bottom: 10px;
}

p {
  color: #666;
  margin-bottom: 20px;
}

.primary-button {
  background-color: #4CAF50;
  border: none;
  color: white;
  padding: 10px 15px;
  text-align: center;
  text-decoration: none;
  display: inline-block;
  font-size: 14px;
  border-radius: 4px;
  cursor: pointer;
}

.result {
  margin-top: 20px;
  padding: 10px;
  background-color: #f5f5f5;
  border-radius: 4px;
  white-space: pre-wrap;
}
</style>
```

## 构建插件

### package.json 配置

确保 `package.json` 包含适当的构建脚本：

```json
{
  "name": "my-buddy-plugin",
  "version": "1.0.0",
  "description": "我的 Buddy 插件",
  "main": "dist/index.js",
  "scripts": {
    "build": "tsc && vite build",
    "package": "node scripts/package.js"
  },
  "keywords": ["buddy", "plugin"],
  "author": "您的名字",
  "license": "MIT",
  "devDependencies": {
    "typescript": "^4.5.4",
    "vite": "^2.7.2",
    "vue": "^3.2.25",
    "@vitejs/plugin-vue": "^2.0.0",
    "archiver": "^5.3.0"
  }
}
```

### 构建脚本

创建一个打包脚本 `scripts/package.js`：

```javascript
const fs = require('fs');
const path = require('path');
const archiver = require('archiver');

async function packagePlugin() {
  // 插件名称和版本
  const manifest = JSON.parse(fs.readFileSync('manifest.json', 'utf8'));
  const { id, version } = manifest;
  const outputFile = path.join('dist', `${id}-${version}.buddy`);
  
  // 创建一个文件输出流
  const output = fs.createWriteStream(outputFile);
  const archive = archiver('zip', {
    zlib: { level: 9 } // 设置压缩级别
  });
  
  // 监听输出流关闭事件
  output.on('close', () => {
    console.log(`插件打包完成: ${outputFile}`);
    console.log(`总大小: ${archive.pointer()} 字节`);
  });
  
  // 监听警告事件
  archive.on('warning', (err) => {
    if (err.code === 'ENOENT') {
      console.warn(err);
    } else {
      throw err;
    }
  });
  
  // 监听错误事件
  archive.on('error', (err) => {
    throw err;
  });
  
  // 将输出流连接到归档对象
  archive.pipe(output);
  
  // 添加文件到归档
  archive.file('manifest.json', { name: 'manifest.json' });
  archive.file('package.json', { name: 'package.json' });
  archive.file('README.md', { name: 'README.md' });
  
  // 添加构建输出目录
  archive.directory('dist/js', 'js');
  archive.directory('dist/components', 'components');
  
  // 添加静态资源
  archive.directory('assets', 'assets');
  
  // 完成归档
  await archive.finalize();
}

packagePlugin().catch(console.error);
```

### 构建命令

运行以下命令构建和打包插件：

```bash
# 构建插件
npm run build

# 打包插件
npm run package
```

## 测试插件

### 本地测试

1. 构建并打包插件
2. 在 Buddy 应用中，进入插件管理界面
3. 选择"从文件安装插件"
4. 选择上一步生成的 `.buddy` 文件
5. 按照提示安装插件

### 调试技巧

1. **检查日志**：插件的日志会输出到 Buddy 应用的控制台，可以通过 DevTools 查看。
2. **使用断点**：可以在 Buddy 的开发者工具中设置断点来调试插件代码。
3. **实时重载**：在开发模式下，修改插件代码后可以重新加载插件而无需重启应用。

## 发布插件

### 准备发布

1. 确保 `manifest.json` 中的信息准确无误
2. 编写详细的 README.md 文件，包括：
   - 插件功能介绍
   - 安装方法
   - 使用指南
   - 权限说明
   - 版本历史
   - 联系方式

### 发布插件

您可以通过以下方式发布插件：

1. **个人网站**：将 `.buddy` 文件上传到您的网站
2. **GitHub**：作为项目的发布附件提供
3. **插件市场**：提交到 Buddy 的官方插件市场（如果可用）

## 插件开发最佳实践

### 1. 遵循权限最小化原则

只请求插件绝对需要的权限。每一项额外的权限都可能降低用户安装您插件的意愿。

### 2. 提供清晰的用户界面

- 使用一致的设计风格
- 提供清晰的操作提示
- 处理错误并显示用户友好的消息

### 3. 优化性能

- 避免不必要的计算和网络请求
- 合理缓存数据
- 避免阻塞主线程

### 4. 版本管理

使用语义化版本控制：

- **主版本号**：不兼容的 API 变更
- **次版本号**：向后兼容的功能性新增
- **修订号**：向后兼容的问题修正

### 5. 文档

为您的插件提供详细的文档：

- 功能说明
- 使用示例
- API 文档（如果插件提供 API）
- 常见问题解答

## 常见问题

### 我的插件无法访问某些 API，为什么？

检查 `manifest.json` 中是否正确声明了所需的权限。

### 如何与其他插件交互？

可以通过 `buddy.events` 系统发送和接收事件实现插件间通信。

### 如何存储用户设置？

使用 `buddy.store` API 来持久化保存插件设置。

### 我的插件能否修改 Buddy 应用的 UI？

插件可以通过注册自定义视图和菜单项来扩展 UI，但不能直接修改应用的核心 UI。

## 资源链接

- [Buddy 插件 API 文档](./07-api-reference.md)
- [示例插件仓库](https://github.com/buddy-app/plugin-examples)
- [Vue.js 官方文档](https://vuejs.org/)
- [TypeScript 官方文档](https://www.typescriptlang.org/docs/)
