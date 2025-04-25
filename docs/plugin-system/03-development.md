# GitOK 插件开发指南

本文档将指导您完成 GitOK 插件的开发过程，从环境设置到发布您的插件。

## 准备工作

### 开发环境需求

开发 GitOK 插件需要以下工具：

- **Node.js** (v14+)
- **npm** 或 **pnpm** 包管理器
- 文本编辑器或 IDE (推荐使用 VSCode)
- GitOK 应用 (用于测试插件)

### 设置开发目录

您可以在两种位置开发插件：

1. **本地开发**：在 GitOK 的 `packages/plugins` 目录中直接开发
2. **独立开发**：在任何位置创建项目，完成后复制到 GitOK 的插件目录

对于本指南，我们将使用本地开发方式：

```bash
# 进入GitOK项目目录
cd /path/to/GitOK

# 创建新的插件目录
mkdir -p packages/plugins/my-plugin

# 进入插件目录
cd packages/plugins/my-plugin
```

## 创建基本插件结构

### 初始化项目

首先，初始化一个新的 npm 项目：

```bash
# 使用npm
npm init

# 或使用pnpm
pnpm init
```

在交互式提示中，填写您的插件信息。重要字段包括：

- **name**：插件名称，建议使用 `gitok-` 前缀，如 `gitok-my-plugin`
- **version**：版本号，建议从 `1.0.0` 开始
- **description**：插件功能描述
- **main**：入口文件，通常是 `index.js`
- **author**：您的名字或组织

### 添加 GitOK 插件信息

修改生成的 `package.json` 文件，添加 `gitokPlugin` 部分：

```json
{
  "name": "gitok-my-plugin",
  "version": "1.0.0",
  "description": "我的第一个 GitOK 插件",
  "main": "index.js",
  "gitokPlugin": {
    "id": "my-plugin"
  },
  "author": "您的名字",
  "license": "MIT"
}
```

`gitokPlugin.id` 是插件的唯一标识符，应该是一个简短、有意义且唯一的名称。

### 创建插件主文件

创建 `index.js` 作为插件的入口点：

```javascript
/**
 * GitOK示例插件
 * 这是我的第一个 GitOK 插件
 */

// 插件ID
const PLUGIN_ID = 'my-plugin';

// 日志函数
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

// 插件对象
const plugin = {
  id: PLUGIN_ID,
  name: '我的插件',
  description: '这是我的第一个 GitOK 插件',
  version: '1.0.0',
  author: '您的名字',

  /**
   * 获取插件提供的动作列表
   * @param {string} keyword 搜索关键词
   * @returns {Promise<Array>} 动作列表
   */
  async getActions(keyword = '') {
    log.info(`获取动作列表，关键词: "${keyword}"`);

    // 定义插件动作
    const actions = [
      {
        id: `${PLUGIN_ID}:hello`,
        title: '问候',
        description: '显示一个问候消息',
        icon: '👋',
        plugin: PLUGIN_ID,
      },
    ];

    // 如果有关键词，过滤动作
    if (keyword) {
      const lowerKeyword = keyword.toLowerCase();
      return actions.filter(
        (action) =>
          action.title.toLowerCase().includes(lowerKeyword) ||
          action.description.toLowerCase().includes(lowerKeyword)
      );
    }

    return actions;
  },

  /**
   * 执行插件动作
   * @param {Object} action 要执行的动作
   * @returns {Promise<any>} 动作执行结果
   */
  async executeAction(action) {
    log.info(`执行动作: ${action.id}`);

    switch (action.id) {
      case `${PLUGIN_ID}:hello`:
        return { message: '你好，这是我的第一个 GitOK 插件！' };

      default:
        throw new Error(`未知的动作ID: ${action.id}`);
    }
  },
};

// 插件初始化日志
log.info(`插件已加载: ${plugin.name} v${plugin.version}`);

// 导出插件对象
module.exports = plugin;
```

这个基本结构实现了所需的插件接口，并提供了一个简单的 "Hello" 动作。

## 测试基本插件

### 启动 GitOK 进行测试

现在可以启动 GitOK 应用来测试您的插件：

```bash
# 在GitOK根目录下
pnpm start
```

启动后，应该能够在搜索栏中找到您的插件动作。

## 添加高级功能

### 添加带视图的动作

现在让我们添加一个带有自定义视图的动作。首先创建视图目录：

```bash
mkdir -p views
```

#### 1. 创建视图文件

创建 `views/counter.html` 文件：

```html
<!DOCTYPE html>
<html>
  <head>
    <title>计数器</title>
    <style>
      body {
        font-family:
          system-ui,
          -apple-system,
          BlinkMacSystemFont,
          sans-serif;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        height: 100vh;
        margin: 0;
        background-color: #f0f0f0;
      }
      .counter {
        display: flex;
        flex-direction: column;
        align-items: center;
        padding: 2rem;
        background-color: white;
        border-radius: 8px;
        box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
      }
      .value {
        font-size: 4rem;
        font-weight: bold;
        margin: 1rem 0;
      }
      .buttons {
        display: flex;
        gap: 0.5rem;
      }
      button {
        padding: 0.5rem 1rem;
        background-color: #4caf50;
        color: white;
        border: none;
        border-radius: 4px;
        cursor: pointer;
        font-size: 1rem;
      }
      button:hover {
        background-color: #3e8e41;
      }
      button.reset {
        background-color: #f44336;
      }
      button.reset:hover {
        background-color: #d32f2f;
      }
    </style>
  </head>
  <body>
    <div class="counter">
      <h2>简单计数器</h2>
      <div class="value" id="value">0</div>
      <div class="buttons">
        <button id="decrement">-1</button>
        <button id="increment">+1</button>
        <button class="reset" id="reset">重置</button>
      </div>
    </div>

    <script>
      // 初始计数值
      let count = 0;

      // 获取元素
      const valueElement = document.getElementById('value');
      const incrementButton = document.getElementById('increment');
      const decrementButton = document.getElementById('decrement');
      const resetButton = document.getElementById('reset');

      // 更新显示
      function updateValue() {
        valueElement.textContent = count;
      }

      // 增加按钮
      incrementButton.addEventListener('click', () => {
        count++;
        updateValue();
        console.log('计数增加到:', count);
      });

      // 减少按钮
      decrementButton.addEventListener('click', () => {
        count--;
        updateValue();
        console.log('计数减少到:', count);
      });

      // 重置按钮
      resetButton.addEventListener('click', () => {
        count = 0;
        updateValue();
        console.log('计数已重置');
      });

      // 初始化
      console.log('计数器视图已加载');
    </script>
  </body>
</html>
```

#### 2. 更新插件主文件

修改 `index.js` 添加新的动作和视图支持：

```javascript
/**
 * GitOK示例插件
 * 这是我的第一个 GitOK 插件
 */

// 插件ID
const PLUGIN_ID = 'my-plugin';
const fs = require('fs');
const path = require('path');

// 日志函数
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

// 插件对象
const plugin = {
  id: PLUGIN_ID,
  name: '我的插件',
  description: '这是我的第一个 GitOK 插件',
  version: '1.0.0',
  author: '您的名字',

  /**
   * 获取插件提供的动作列表
   * @param {string} keyword 搜索关键词
   * @returns {Promise<Array>} 动作列表
   */
  async getActions(keyword = '') {
    log.info(`获取动作列表，关键词: "${keyword}"`);

    // 定义插件动作
    const actions = [
      {
        id: `${PLUGIN_ID}:hello`,
        title: '问候',
        description: '显示一个问候消息',
        icon: '👋',
        plugin: PLUGIN_ID,
      },
      {
        id: `${PLUGIN_ID}:counter`,
        title: '计数器',
        description: '简单的计数器示例',
        icon: '🔢',
        plugin: PLUGIN_ID,
        viewPath: 'views/counter.html',
      },
    ];

    // 如果有关键词，过滤动作
    if (keyword) {
      const lowerKeyword = keyword.toLowerCase();
      return actions.filter(
        (action) =>
          action.title.toLowerCase().includes(lowerKeyword) ||
          action.description.toLowerCase().includes(lowerKeyword)
      );
    }

    return actions;
  },

  /**
   * 执行插件动作
   * @param {Object} action 要执行的动作
   * @returns {Promise<any>} 动作执行结果
   */
  async executeAction(action) {
    log.info(`执行动作: ${action.id}`);

    switch (action.id) {
      case `${PLUGIN_ID}:hello`:
        return { message: '你好，这是我的第一个 GitOK 插件！' };

      case `${PLUGIN_ID}:counter`:
        // 这个动作有视图，只需返回成功
        return { success: true };

      default:
        throw new Error(`未知的动作ID: ${action.id}`);
    }
  },

  /**
   * 获取视图内容
   * @param {string} viewPath 视图路径
   * @returns {Promise<string>} HTML内容
   */
  async getViewContent(viewPath) {
    log.info(`获取视图内容: ${viewPath}`);

    try {
      // 读取视图文件
      const filePath = path.join(__dirname, viewPath);
      if (!fs.existsSync(filePath)) {
        throw new Error(`视图文件不存在: ${filePath}`);
      }

      const content = fs.readFileSync(filePath, 'utf-8');
      log.debug(`成功读取视图文件，大小: ${content.length} 字节`);
      return content;
    } catch (error) {
      log.error(`获取视图内容失败:`, error);
      throw error;
    }
  },
};

// 插件初始化日志
log.info(`插件已加载: ${plugin.name} v${plugin.version}`);

// 导出插件对象
module.exports = plugin;
```

### 访问 Node.js 功能

插件可以访问 Node.js API，例如文件系统、进程和网络。示例：

```javascript
// 在插件中使用Node.js API
const fs = require('fs');
const os = require('os');
const { exec } = require('child_process');

// 读取文件
async function readConfigFile() {
  const configPath = path.join(os.homedir(), '.myconfig');
  if (fs.existsSync(configPath)) {
    return fs.readFileSync(configPath, 'utf-8');
  }
  return null;
}

// 执行命令
async function executeCommand(cmd) {
  return new Promise((resolve, reject) => {
    exec(cmd, (error, stdout, stderr) => {
      if (error) {
        reject(error);
        return;
      }
      resolve(stdout);
    });
  });
}
```

### 插件配置

插件可以实现配置功能：

```javascript
// 插件配置处理
const configFile = path.join(
  os.homedir(),
  '.gitok',
  'plugins',
  `${PLUGIN_ID}.json`
);

// 读取配置
function loadConfig() {
  try {
    if (fs.existsSync(configFile)) {
      return JSON.parse(fs.readFileSync(configFile, 'utf-8'));
    }
  } catch (error) {
    log.error('读取配置失败:', error);
  }
  return {}; // 默认配置
}

// 保存配置
function saveConfig(config) {
  try {
    // 确保目录存在
    const dir = path.dirname(configFile);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }

    fs.writeFileSync(configFile, JSON.stringify(config, null, 2), 'utf-8');
    return true;
  } catch (error) {
    log.error('保存配置失败:', error);
    return false;
  }
}
```

## 调试插件

### 控制台输出

使用日志函数记录重要信息：

```javascript
log.debug('调试信息');
log.info('一般信息');
log.error('错误信息', error);
```

在 GitOK 应用中，您可以通过 `Ctrl+Shift+I`（Windows/Linux）或 `Cmd+Option+I`（Mac）打开开发者工具查看日志。

### 刷新插件

在开发过程中，修改插件后可以重启 GitOK 应用来重新加载插件。

## 打包和发布插件

### 准备发布

发布前，确保：

1. 更新 `package.json` 中的版本号
2. 编写完善的 README.md 文档
3. 整理代码，移除调试日志
4. 测试所有功能

### 发布选项

您可以通过以下方式发布插件：

1. **本地使用**：直接复制到 GitOK 的插件目录
2. **分享 ZIP**：将插件目录打包为 ZIP 文件分享
3. **发布到 npm**：如果将来支持，可以发布到 npm 仓库

示例打包命令：

```bash
# 创建插件压缩包
cd packages/plugins
zip -r my-plugin.zip my-plugin -x "*/node_modules/*" "*.git*"
```

## 最佳实践

### 插件结构

建议的插件目录结构：

```
my-plugin/
├── index.js          # 主入口文件
├── package.json      # 包信息和依赖
├── README.md         # 使用文档
├── lib/              # 辅助库和功能
│   ├── utils.js
│   └── api.js
└── views/            # 视图文件
    ├── main.html
    └── settings.html
```

### 命名约定

- **插件 ID**：使用短横线分隔的小写字母，如 `my-awesome-plugin`
- **动作 ID**：使用 `${PLUGIN_ID}:动作名称` 格式，如 `my-plugin:hello`
- **视图路径**：使用相对于插件根目录的路径，如 `views/main.html`

### 错误处理

始终进行适当的错误处理：

```javascript
async function doSomething() {
  try {
    // 功能代码
    return result;
  } catch (error) {
    log.error('操作失败:', error);
    // 可能的恢复逻辑
    throw new Error(`操作失败: ${error.message}`);
  }
}
```

### 性能注意事项

- 避免在 `getActions()` 中执行耗时操作
- 懒加载资源，只在需要时加载
- 缓存频繁使用的结果
- 在视图中使用高效的 DOM 操作

## 下一步

完成本指南后，您可以：

- [查阅 API 参考文档](./04-api-reference.md)
- [研究示例插件实现](./05-example-plugin.md)
- 探索更高级的功能，如插件间通信

---

© 2023 CofficLab. 保留所有权利。
