/**
 * GitOK示例插件
 * 演示如何创建一个基本的插件，提供动作和自定义视图
 */

// 插件ID
const PLUGIN_ID = 'example-plugin';

// 日志函数
const log = {
  info: function (message, ...args) {
    console.log(`[示例插件] ${message}`, ...args);
  },
  error: function (message, ...args) {
    console.error(`[示例插件] ${message}`, ...args);
  },
  debug: function (message, ...args) {
    console.log(`[示例插件:调试] ${message}`, ...args);
  },
};

// 插件信息
const plugin = {
  id: PLUGIN_ID,
  name: '示例插件',
  description: '这是一个示例插件，演示如何创建GitOK插件',
  version: '1.0.0',
  author: 'Coffic',

  /**
   * 获取插件提供的动作列表
   * @param {string} keyword 搜索关键词
   * @returns {Promise<Array>} 动作列表
   */
  async getActions(keyword = '') {
    log.info(`获取动作列表，关键词: "${keyword}"`);

    // 创建基础动作列表
    const actions = [
      {
        id: `${PLUGIN_ID}:hello`,
        title: '打招呼',
        description: '显示一个问候消息',
        icon: '👋',
        plugin: PLUGIN_ID,
      },
      {
        id: `${PLUGIN_ID}:time`,
        title: '当前时间',
        description: '显示当前时间',
        icon: '🕒',
        plugin: PLUGIN_ID,
        viewPath: 'views/time.html',
      },
      {
        id: `${PLUGIN_ID}:calculate`,
        title: '计算器',
        description: '简单的计算器',
        icon: '🧮',
        plugin: PLUGIN_ID,
        viewPath: 'views/calculator.html',
      },
    ];

    log.debug(`基础动作列表: ${actions.length} 个动作`);

    // 如果有关键词，过滤匹配的动作
    if (keyword) {
      const lowerKeyword = keyword.toLowerCase();
      log.debug(`过滤包含关键词 "${lowerKeyword}" 的动作`);

      const filteredActions = actions.filter(
        (action) =>
          action.title.toLowerCase().includes(lowerKeyword) ||
          action.description.toLowerCase().includes(lowerKeyword)
      );

      log.info(`过滤后返回 ${filteredActions.length} 个动作`);
      return filteredActions;
    }

    log.info(`返回所有 ${actions.length} 个动作`);
    return actions;
  },

  /**
   * 执行插件动作
   * @param {Object} action 要执行的动作
   * @returns {Promise<any>} 动作执行结果
   */
  async executeAction(action) {
    log.info(`执行动作: ${action.id} (${action.title})`);

    try {
      switch (action.id) {
        case `${PLUGIN_ID}:hello`:
          log.debug(`执行打招呼动作`);
          return { message: '你好，这是来自示例插件的问候！' };

        case `${PLUGIN_ID}:time`:
          log.debug(`执行时间动作（有自定义视图）`);
          return { success: true };

        case `${PLUGIN_ID}:calculate`:
          log.debug(`执行计算器动作（有自定义视图）`);
          return { success: true };

        default:
          const errorMsg = `未知的动作ID: ${action.id}`;
          log.error(errorMsg);
          throw new Error(errorMsg);
      }
    } catch (error) {
      log.error(`执行动作 ${action.id} 失败:`, error);
      throw error;
    }
  },

  /**
   * 获取视图内容
   * @param {string} viewPath 视图路径
   * @returns {Promise<string>} HTML内容
   */
  async getViewContent(viewPath) {
    log.info(`获取视图内容: ${viewPath}`);

    // 在实际应用中，你应该读取文件系统中的视图文件
    try {
      // 演示目的，直接返回内联HTML
      let html;

      switch (viewPath) {
        case 'views/time.html':
          log.debug(`生成时间视图HTML`);
          html = `
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
                    background-color: #f0f0f0;
                    color: #333;
                  }
                  .time {
                    font-size: 4rem;
                    font-weight: bold;
                    margin-bottom: 1rem;
                  }
                  .date {
                    font-size: 1.5rem;
                  }
                </style>
              </head>
              <body>
                <div class="time" id="time"></div>
                <div class="date" id="date"></div>
                
                <script>
                  function updateTime() {
                    const now = new Date();
                    
                    // 格式化时间
                    const timeElement = document.getElementById('time');
                    timeElement.textContent = now.toLocaleTimeString('zh-CN', {
                      hour: '2-digit',
                      minute: '2-digit',
                      second: '2-digit'
                    });
                    
                    // 格式化日期
                    const dateElement = document.getElementById('date');
                    dateElement.textContent = now.toLocaleDateString('zh-CN', {
                      year: 'numeric',
                      month: 'long',
                      day: 'numeric',
                      weekday: 'long'
                    });
                  }
                  
                  // 初始更新
                  updateTime();
                  
                  // 每秒更新一次
                  setInterval(updateTime, 1000);
                  
                  // 添加调试日志
                  console.log("[示例插件:时间视图] 视图已加载，计时器已启动");
                </script>
              </body>
            </html>
          `;
          break;

        case 'views/calculator.html':
          log.debug(`生成计算器视图HTML`);
          html = `
            <!DOCTYPE html>
            <html>
              <head>
                <title>简单计算器</title>
                <style>
                  body {
                    font-family: system-ui, -apple-system, BlinkMacSystemFont, sans-serif;
                    display: flex;
                    flex-direction: column;
                    align-items: center;
                    justify-content: center;
                    height: 100vh;
                    margin: 0;
                    background-color: #f0f0f0;
                  }
                  .calculator {
                    width: 240px;
                    border: 1px solid #ccc;
                    border-radius: 5px;
                    box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
                    overflow: hidden;
                  }
                  .display {
                    background-color: #333;
                    color: white;
                    text-align: right;
                    padding: 10px;
                    font-size: 24px;
                    height: 40px;
                  }
                  .buttons {
                    display: grid;
                    grid-template-columns: repeat(4, 1fr);
                    gap: 1px;
                    background-color: #ccc;
                  }
                  button {
                    border: none;
                    outline: none;
                    background-color: white;
                    font-size: 20px;
                    height: 50px;
                    cursor: pointer;
                  }
                  button:hover {
                    background-color: #f0f0f0;
                  }
                  button.operator {
                    background-color: #f8f8f8;
                  }
                  button.equals {
                    background-color: #ff9800;
                    color: white;
                  }
                </style>
              </head>
              <body>
                <div class="calculator">
                  <div class="display" id="display">0</div>
                  <div class="buttons">
                    <button onclick="clearDisplay()">C</button>
                    <button onclick="backspace()">⌫</button>
                    <button onclick="appendOperator('%')">%</button>
                    <button class="operator" onclick="appendOperator('/')">÷</button>
                    
                    <button onclick="appendNumber(7)">7</button>
                    <button onclick="appendNumber(8)">8</button>
                    <button onclick="appendNumber(9)">9</button>
                    <button class="operator" onclick="appendOperator('*')">×</button>
                    
                    <button onclick="appendNumber(4)">4</button>
                    <button onclick="appendNumber(5)">5</button>
                    <button onclick="appendNumber(6)">6</button>
                    <button class="operator" onclick="appendOperator('-')">-</button>
                    
                    <button onclick="appendNumber(1)">1</button>
                    <button onclick="appendNumber(2)">2</button>
                    <button onclick="appendNumber(3)">3</button>
                    <button class="operator" onclick="appendOperator('+')">+</button>
                    
                    <button onclick="appendNumber(0)" style="grid-column: span 2;">0</button>
                    <button onclick="appendDecimal()">.</button>
                    <button class="equals" onclick="calculate()">=</button>
                  </div>
                </div>
                
                <script>
                  // 添加调试日志
                  console.log("[示例插件:计算器视图] 视图已加载");
                  
                  let displayValue = '0';
                  let waitingForOperand = false;
                  const display = document.getElementById('display');
                  
                  function updateDisplay() {
                    display.textContent = displayValue;
                  }
                  
                  function appendNumber(number) {
                    console.log("[示例插件:计算器视图] 输入数字:", number);
                    if (waitingForOperand) {
                      displayValue = String(number);
                      waitingForOperand = false;
                    } else {
                      displayValue = displayValue === '0' ? String(number) : displayValue + number;
                    }
                    updateDisplay();
                  }
                  
                  function appendDecimal() {
                    console.log("[示例插件:计算器视图] 输入小数点");
                    if (waitingForOperand) {
                      displayValue = '0.';
                      waitingForOperand = false;
                    } else if (!displayValue.includes('.')) {
                      displayValue += '.';
                    }
                    updateDisplay();
                  }
                  
                  function appendOperator(operator) {
                    console.log("[示例插件:计算器视图] 输入运算符:", operator);
                    displayValue += operator;
                    waitingForOperand = false;
                    updateDisplay();
                  }
                  
                  function clearDisplay() {
                    console.log("[示例插件:计算器视图] 清空显示");
                    displayValue = '0';
                    waitingForOperand = false;
                    updateDisplay();
                  }
                  
                  function backspace() {
                    console.log("[示例插件:计算器视图] 退格");
                    if (displayValue.length > 1) {
                      displayValue = displayValue.slice(0, -1);
                    } else {
                      displayValue = '0';
                    }
                    updateDisplay();
                  }
                  
                  function calculate() {
                    console.log("[示例插件:计算器视图] 计算结果");
                    try {
                      // eslint-disable-next-line no-eval
                      displayValue = String(eval(displayValue));
                      console.log("[示例插件:计算器视图] 计算结果:", displayValue);
                      waitingForOperand = true;
                    } catch (e) {
                      console.error("[示例插件:计算器视图] 计算错误:", e);
                      displayValue = 'Error';
                    }
                    updateDisplay();
                  }
                </script>
              </body>
            </html>
          `;
          break;

        default:
          const errorMsg = `未知的视图路径: ${viewPath}`;
          log.error(errorMsg);
          throw new Error(errorMsg);
      }

      log.info(`成功生成视图HTML，长度: ${html.length} 字节`);
      return html;
    } catch (error) {
      log.error(`获取视图内容失败:`, error);
      throw error;
    }
  },
};

// 插件初始化输出
log.info(`示例插件已加载: ${plugin.name} v${plugin.version}`);

// 导出插件
module.exports = plugin;
