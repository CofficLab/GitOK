# GitOK 示例插件解析

本文档对 GitOK 自带的示例插件进行详细解析，帮助开发者了解插件结构和实现方式。通过分析这个示例，你可以学习如何创建自己的插件。

## 示例插件概述

GitOK 示例插件（gitok-example-plugin）是一个简单但功能完整的插件，演示了插件的基本结构、动作定义、执行逻辑以及自定义视图的实现。该插件提供了多个示例动作，包括时间显示和简易计算器功能。

## 文件结构

```
example-plugin/
├── package.json       # 插件元数据和配置
└── index.js           # 插件主逻辑实现
```

## package.json 解析

```json
{
  "name": "gitok-example-plugin",
  "version": "1.0.0",
  "description": "GitOK示例插件",
  "main": "index.js",
  "gitokPlugin": {
    "id": "example-plugin"
  },
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "author": "Coffic",
  "license": "MIT"
}
```

**关键点解析：**

1. **name**: 采用 `gitok-` 前缀命名，符合插件命名约定
2. **gitokPlugin.id**: 定义唯一插件标识符，用于系统识别
3. **main**: 指定插件的入口文件
4. **description**: 简要描述插件功能

## 插件入口文件解析

下面对 `index.js` 的主要部分进行解析：

### 1. 插件常量和日志功能

```javascript
/**
 * GitOK示例插件
 * 演示如何创建一个基本的插件，包含动作和自定义视图
 */

const PLUGIN_ID = 'example-plugin';

// 日志功能
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

**解析：**

- 定义插件ID常量，确保在所有方法中一致使用
- 实现日志功能，添加插件ID前缀，便于调试
- 区分不同级别的日志：info, error, debug

### 2. 插件基本元数据

```javascript
// 插件元数据
const metadata = {
  id: PLUGIN_ID,
  name: 'GitOK 示例插件',
  description: '展示插件系统基本功能的示例插件',
  version: '1.0.0',
  author: 'Coffic',
};
```

**解析：**

- 定义插件基本信息，与 package.json 中的信息保持一致
- 这些元数据会在插件管理界面中显示

### 3. 动作定义和获取

```javascript
/**
 * 获取插件提供的动作列表
 * @param {string} keyword 可选的搜索关键词
 * @returns {Promise<Array>} 动作列表
 */
async function getActions(keyword = '') {
  log.debug(`获取动作，关键词: "${keyword}"`);

  // 定义插件提供的所有动作
  const actions = [
    {
      id: `${PLUGIN_ID}:hello`,
      title: '示例问候',
      description: '显示一个来自插件的问候',
      icon: '👋',
      plugin: PLUGIN_ID,
    },
    {
      id: `${PLUGIN_ID}:time`,
      title: '当前时间',
      description: '显示当前时间，每秒更新',
      icon: '🕒',
      plugin: PLUGIN_ID,
      viewPath: 'time-view', // 指定自定义视图
    },
    {
      id: `${PLUGIN_ID}:calc`,
      title: '简易计算器',
      description: '提供简单的计算功能',
      icon: '🧮',
      plugin: PLUGIN_ID,
      viewPath: 'calc-view', // 指定自定义视图
    },
  ];

  // 如果提供了关键词，进行过滤
  if (keyword) {
    const lowerKeyword = keyword.toLowerCase();
    const filtered = actions.filter(
      (action) =>
        action.title.toLowerCase().includes(lowerKeyword) ||
        action.description.toLowerCase().includes(lowerKeyword)
    );
    log.debug(`关键词过滤后返回 ${filtered.length} 个动作`);
    return filtered;
  }

  log.debug(`返回所有 ${actions.length} 个动作`);
  return actions;
}
```

**解析：**

- `getActions` 方法返回插件提供的所有动作
- 每个动作包含唯一ID、标题、描述、图标和插件ID
- 支持通过关键词过滤动作，提高用户查找效率
- 部分动作指定了 `viewPath`，表示它们有自定义视图
- 使用日志记录函数调用和返回情况，便于调试

### 4. 动作执行逻辑

```javascript
/**
 * 执行指定的动作
 * @param {Object} action 要执行的动作对象
 * @returns {Promise<any>} 执行结果
 */
async function executeAction(action) {
  log.debug(`执行动作: ${action.id}`);

  try {
    // 根据动作ID执行不同的逻辑
    switch (action.id) {
      case `${PLUGIN_ID}:hello`:
        log.info('执行问候动作');
        return {
          message: '你好！这是来自示例插件的问候。',
          timestamp: new Date().toISOString(),
        };

      case `${PLUGIN_ID}:time`:
      case `${PLUGIN_ID}:calc`:
        // 这些动作主要依赖于它们的视图，返回基本响应
        log.info(`执行动作: ${action.id}`);
        return { success: true };

      default:
        const errorMsg = `未知的动作ID: ${action.id}`;
        log.error(errorMsg);
        throw new Error(errorMsg);
    }
  } catch (error) {
    log.error(`执行动作出错:`, error);
    throw error;
  }
}
```

**解析：**

- `executeAction` 实现了动作的执行逻辑
- 使用 switch 语句根据动作ID执行不同的处理
- 简单动作如 `hello` 直接返回数据
- 带视图的动作如 `time` 和 `calc` 主要由视图负责展示，返回成功标志
- 错误处理确保遇到问题时给出明确提示

### 5. 视图内容获取

```javascript
/**
 * 获取动作视图的HTML内容
 * @param {string} viewPath 视图路径
 * @returns {Promise<string>} HTML内容
 */
async function getViewContent(viewPath) {
  log.debug(`获取视图内容: ${viewPath}`);

  try {
    // 根据视图路径返回不同的HTML内容
    switch (viewPath) {
      case 'time-view':
        log.info('返回时间视图');
        return `
          <!DOCTYPE html>
          <html>
          <head>
            <title>当前时间</title>
            <style>
              body {
                font-family: system-ui, -apple-system, BlinkMacSystemFont, sans-serif;
                display: flex;
                flex-direction: column;
                align-items: center;
                justify-content: center;
                height: 100vh;
                margin: 0;
                background-color: #f5f5f5;
                color: #333;
              }
              .time-container {
                text-align: center;
                padding: 20px;
                border-radius: 8px;
                background-color: white;
                box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
              }
              .time {
                font-size: 2rem;
                font-weight: bold;
                margin: 10px 0;
              }
              .date {
                font-size: 1.2rem;
                color: #666;
              }
            </style>
          </head>
          <body>
            <div class="time-container">
              <div class="time" id="current-time">00:00:00</div>
              <div class="date" id="current-date">加载中...</div>
            </div>
            
            <script>
              // 更新时间的函数
              function updateTime() {
                const now = new Date();
                
                // 格式化时间
                const hours = String(now.getHours()).padStart(2, '0');
                const minutes = String(now.getMinutes()).padStart(2, '0');
                const seconds = String(now.getSeconds()).padStart(2, '0');
                const timeString = \`\${hours}:\${minutes}:\${seconds}\`;
                
                // 格式化日期
                const options = { 
                  weekday: 'long', 
                  year: 'numeric', 
                  month: 'long', 
                  day: 'numeric' 
                };
                const dateString = now.toLocaleDateString(undefined, options);
                
                // 更新DOM
                document.getElementById('current-time').textContent = timeString;
                document.getElementById('current-date').textContent = dateString;
              }
              
              // 立即更新一次
              updateTime();
              
              // 每秒更新一次
              setInterval(updateTime, 1000);
              
              // 向父窗口发送加载完成消息
              window.parent.postMessage({ type: 'viewLoaded', viewPath: 'time-view' }, '*');
            </script>
          </body>
          </html>
        `;

      case 'calc-view':
        log.info('返回计算器视图');
        return `
          <!DOCTYPE html>
          <html>
          <head>
            <title>简易计算器</title>
            <style>
              body {
                font-family: system-ui, -apple-system, BlinkMacSystemFont, sans-serif;
                display: flex;
                justify-content: center;
                align-items: center;
                height: 100vh;
                margin: 0;
                background-color: #f5f5f5;
              }
              .calculator {
                background-color: white;
                border-radius: 10px;
                box-shadow: 0 4px 15px rgba(0, 0, 0, 0.15);
                width: 280px;
                padding: 15px;
              }
              .display {
                background-color: #f8f8f8;
                border: 1px solid #ddd;
                border-radius: 5px;
                padding: 10px;
                margin-bottom: 15px;
                text-align: right;
                font-size: 1.5rem;
                min-height: 1.5rem;
              }
              .buttons {
                display: grid;
                grid-template-columns: repeat(4, 1fr);
                gap: 8px;
              }
              button {
                background-color: #f1f1f1;
                border: none;
                border-radius: 5px;
                color: #333;
                font-size: 1.2rem;
                padding: 12px;
                cursor: pointer;
                transition: background-color 0.2s;
              }
              button:hover {
                background-color: #e0e0e0;
              }
              .operator {
                background-color: #FFB74D;
                color: white;
              }
              .equals {
                background-color: #4CAF50;
                color: white;
              }
              .clear {
                background-color: #F44336;
                color: white;
              }
            </style>
          </head>
          <body>
            <div class="calculator">
              <div class="display" id="display">0</div>
              <div class="buttons">
                <button class="clear" id="clear">C</button>
                <button class="operator" id="backspace">⌫</button>
                <button class="operator" id="percentage">%</button>
                <button class="operator" id="divide">÷</button>
                
                <button class="number" id="btn7">7</button>
                <button class="number" id="btn8">8</button>
                <button class="number" id="btn9">9</button>
                <button class="operator" id="multiply">×</button>
                
                <button class="number" id="btn4">4</button>
                <button class="number" id="btn5">5</button>
                <button class="number" id="btn6">6</button>
                <button class="operator" id="subtract">−</button>
                
                <button class="number" id="btn1">1</button>
                <button class="number" id="btn2">2</button>
                <button class="number" id="btn3">3</button>
                <button class="operator" id="add">+</button>
                
                <button class="number" id="btn0">0</button>
                <button class="number" id="decimal">.</button>
                <button class="equals" id="equals">=</button>
              </div>
            </div>
            
            <script>
              // 计算器状态
              let displayValue = '0';
              let firstOperand = null;
              let operator = null;
              let waitingForSecondOperand = false;
              
              // 获取显示元素
              const display = document.getElementById('display');
              
              // 更新显示内容
              function updateDisplay() {
                display.textContent = displayValue;
              }
              
              // 输入数字
              function inputDigit(digit) {
                if (waitingForSecondOperand) {
                  displayValue = digit;
                  waitingForSecondOperand = false;
                } else {
                  displayValue = displayValue === '0' ? digit : displayValue + digit;
                }
                updateDisplay();
              }
              
              // 输入小数点
              function inputDecimal() {
                if (waitingForSecondOperand) {
                  displayValue = '0.';
                  waitingForSecondOperand = false;
                  updateDisplay();
                  return;
                }
                
                if (!displayValue.includes('.')) {
                  displayValue += '.';
                  updateDisplay();
                }
              }
              
              // 处理运算符
              function handleOperator(nextOperator) {
                const inputValue = parseFloat(displayValue);
                
                if (firstOperand === null) {
                  firstOperand = inputValue;
                } else if (operator) {
                  const result = calculate(firstOperand, inputValue, operator);
                  displayValue = String(result);
                  firstOperand = result;
                }
                
                waitingForSecondOperand = true;
                operator = nextOperator;
                updateDisplay();
              }
              
              // 计算结果
              function calculate(firstOperand, secondOperand, operator) {
                switch (operator) {
                  case '+': return firstOperand + secondOperand;
                  case '-': return firstOperand - secondOperand;
                  case '*': return firstOperand * secondOperand;
                  case '/': return firstOperand / secondOperand;
                  case '%': return firstOperand % secondOperand;
                  default: return secondOperand;
                }
              }
              
              // 重置计算器
              function resetCalculator() {
                displayValue = '0';
                firstOperand = null;
                operator = null;
                waitingForSecondOperand = false;
                updateDisplay();
              }
              
              // 删除最后一位
              function backspace() {
                if (displayValue.length > 1) {
                  displayValue = displayValue.slice(0, -1);
                } else {
                  displayValue = '0';
                }
                updateDisplay();
              }
              
              // 添加数字按钮事件监听
              for (let i = 0; i <= 9; i++) {
                document.getElementById(\`btn\${i}\`).addEventListener('click', () => inputDigit(i.toString()));
              }
              
              // 添加运算符按钮事件监听
              document.getElementById('add').addEventListener('click', () => handleOperator('+'));
              document.getElementById('subtract').addEventListener('click', () => handleOperator('-'));
              document.getElementById('multiply').addEventListener('click', () => handleOperator('*'));
              document.getElementById('divide').addEventListener('click', () => handleOperator('/'));
              document.getElementById('percentage').addEventListener('click', () => handleOperator('%'));
              document.getElementById('equals').addEventListener('click', () => {
                if (operator && !waitingForSecondOperand) {
                  const inputValue = parseFloat(displayValue);
                  const result = calculate(firstOperand, inputValue, operator);
                  displayValue = String(result);
                  firstOperand = result;
                  operator = null;
                  waitingForSecondOperand = false;
                  updateDisplay();
                }
              });
              
              // 其他按钮事件监听
              document.getElementById('clear').addEventListener('click', resetCalculator);
              document.getElementById('backspace').addEventListener('click', backspace);
              document.getElementById('decimal').addEventListener('click', inputDecimal);
              
              // 初始化显示
              updateDisplay();
              
              // 向父窗口发送加载完成消息
              window.parent.postMessage({ type: 'viewLoaded', viewPath: 'calc-view' }, '*');
            </script>
          </body>
          </html>
        `;

      default:
        const errorMsg = `未找到视图: ${viewPath}`;
        log.error(errorMsg);
        throw new Error(errorMsg);
    }
  } catch (error) {
    log.error(`获取视图内容出错:`, error);
    throw error;
  }
}
```

**解析：**

- `getViewContent` 方法提供动作视图的 HTML 内容
- 每个视图是完整的 HTML 文档，包含样式和脚本
- 视图通过 iframe 在 GitOK 应用中显示
- 时间视图展示当前时间，并通过 JavaScript 每秒更新
- 计算器视图实现了一个功能完整的简易计算器
- 两个视图都会在加载完成后通过 `postMessage` 通知父窗口

### 6. 模块导出

```javascript
// 导出插件接口
module.exports = {
  ...metadata,
  getActions,
  executeAction,
  getViewContent,
};
```

**解析：**

- 使用 Node.js 的 CommonJS 模块系统导出接口
- 导出元数据和三个主要方法：getActions, executeAction, getViewContent
- 这种结构确保了插件符合 GitOK 插件系统的接口要求

## 关键实现技巧

### 1. 插件标识符一致性

示例插件使用常量 `PLUGIN_ID` 确保在整个插件中一致使用相同的标识符，避免拼写错误。

### 2. 动作ID格式

动作ID采用 `pluginId:actionName` 格式，确保动作在全局范围内唯一，便于系统识别和路由。

### 3. 结构化日志

实现了结构化日志系统，分级记录信息、错误和调试信息，便于排查问题。

### 4. 视图内容生成

动态生成完整的 HTML 文档，包含样式和脚本，实现自包含的视图功能。

### 5. 错误处理

各个方法都实现了错误捕获和报告，确保插件运行稳定，提供清晰的错误信息。

### 6. 与宿主应用通信

视图通过 `window.parent.postMessage()` 与主应用通信，报告加载完成状态。

## 插件使用流程

1. GitOK 加载示例插件
2. 用户打开插件页面，系统调用 `getActions()` 获取所有动作
3. 用户选择动作（如"当前时间"），系统调用 `executeAction()`
4. 如果动作有视图，系统调用 `getViewContent()` 获取视图内容
5. 视图在 iframe 中渲染，并在加载完成后通知主应用

## 扩展示例插件的思路

基于此示例插件，你可以通过以下方式进行扩展：

1. **添加新动作**：在 `getActions()` 中添加新的动作定义
2. **增强现有视图**：改进时间显示或计算器功能
3. **添加配置选项**：实现配置保存和加载功能
4. **实现 Node.js 功能**：添加文件系统操作或网络请求
5. **添加更丰富的 UI**：使用框架如 Vue 或 React 创建复杂视图

## 最佳实践总结

从示例插件中可以学到的最佳实践：

1. **清晰的代码结构**：功能分离，方法职责明确
2. **完善的错误处理**：捕获并报告所有可能的错误
3. **详细的日志**：记录关键操作，便于调试
4. **响应式设计**：视图适应不同尺寸
5. **优雅的用户体验**：提供视觉反馈和交互效果

## 结论

GitOK 的示例插件虽然简单，但展示了开发插件所需的所有核心概念和技术。通过学习和扩展这个示例，你可以开发出功能丰富、用户体验良好的自定义插件。

下一步，尝试基于这个示例创建你自己的第一个 GitOK 插件吧！

---

© 2023 CofficLab. 保留所有权利。
