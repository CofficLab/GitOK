# 3. 插件格式规范

Buddy 插件采用标准化的格式，以确保系统能够一致地安装、加载和执行插件。

## 插件包格式

插件以 `.buddy` 文件形式分发，本质上是一个 ZIP 压缩文件，包含以下结构：

```text
my-plugin.buddy
├── manifest.json        # 插件清单（必需）
├── index.js             # 插件主文件（由manifest.json中的main字段指定）
├── components/          # Vue组件目录（可选）
│   ├── MainView.vue     # 主视图组件
│   └── SettingsView.vue # 设置视图组件
├── assets/              # 静态资源目录（可选）
│   ├── icon.svg         # 插件图标
│   └── images/          # 其他图片资源
└── LICENSE              # 许可证文件（可选）
```

## 插件清单格式

每个插件必须在根目录包含一个 `manifest.json` 文件，定义插件的元数据和配置。

示例清单：

```json
{
  "id": "my-awesome-plugin",
  "name": "我的插件",
  "version": "1.0.0",
  "description": "这是一个示例插件",
  "author": "开发者名称",
  "main": "index.js",
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
  ],
  "commands": [
    {
      "id": "my-plugin.doSomething",
      "title": "执行操作",
      "shortcut": "Ctrl+Shift+P"
    }
  ],
  "configuration": {
    "apiKey": {
      "type": "string",
      "default": "",
      "description": "API密钥"
    },
    "enableFeature": {
      "type": "boolean",
      "default": true,
      "description": "启用特性"
    }
  }
}
```

### 字段说明

| 字段 | 类型 | 必需 | 描述 |
|------|------|------|------|
| `id` | 字符串 | 是 | 插件的唯一标识符 |
| `name` | 字符串 | 是 | 插件的显示名称 |
| `version` | 字符串 | 是 | 遵循语义化版本的版本号 |
| `description` | 字符串 | 是 | 插件的简短描述 |
| `author` | 字符串 | 否 | 插件作者信息 |
| `main` | 字符串 | 是 | 插件主文件的路径 |
| `engines` | 对象 | 否 | 兼容性要求 |
| `views` | 数组 | 否 | 插件提供的视图定义 |
| `permissions` | 数组 | 否 | 插件请求的权限列表 |
| `commands` | 数组 | 否 | 插件提供的命令 |
| `configuration` | 对象 | 否 | 插件配置选项 |

## 插件主文件格式

插件主文件（由清单中的 `main` 字段指定）是一个 JavaScript 模块，导出以下接口：

```js
/**
 * 插件主模块
 */
class MyPlugin {
  /**
   * 初始化插件
   * 在插件加载时调用
   */
  async initialize() {
    console.log('插件初始化中...');
  }
  
  /**
   * 激活插件
   * 在插件需要激活时调用
   */
  async activate() {
    console.log('插件已激活');
  }
  
  /**
   * 停用插件
   * 在插件停用时调用
   */
  async deactivate() {
    console.log('插件已停用');
  }
}

// 导出插件实例
export default new MyPlugin();
```

## 视图组件格式

插件的视图组件是标准的 Vue 组件：

```vue
<template>
  <div class="my-plugin-view">
    <h1>{{ title }}</h1>
    <p>{{ message }}</p>
    <button @click="handleClick">点击我</button>
  </div>
</template>

<script setup>
import { ref } from 'vue';

const title = ref('我的插件视图');
const message = ref('这是一个插件提供的视图');

function handleClick() {
  message.value = '按钮被点击了！';
}
</script>

<style scoped>
.my-plugin-view {
  padding: 20px;
}
</style>
``` 