const fs = require('fs');
const path = require('path');

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
  name: '示例插件',
  description: '这是一个示例插件，演示如何创建GitOK插件',
  version: '1.0.0',
  author: 'Coffic',

  /**
   * 获取插件提供的动作列表
   * @param {Object} context 插件上下文
   * @param {string} context.keyword 搜索关键词
   * @param {string} context.overlaidApp 被覆盖应用名称
   * @returns {Promise<Array>} 动作列表
   */
  async getActions({ keyword = '', overlaidApp = '' }) {
    log.info(
      `获取动作列表，关键词: "${keyword}", 被覆盖应用: "${overlaidApp}"`
    );

    // 创建基础动作列表
    const actions = [
      {
        id: `hello`,
        title: '打招呼',
        description: '显示一个问候消息',
        icon: '👋',
      },
      {
        id: `time`,
        title: '当前时间',
        description: '显示当前时间',
        icon: '🕒',
        viewPath: 'views/time.html',
        viewMode: 'embedded',
        devTools: false,
      },
      {
        id: `calculate`,
        title: '计算器',
        description: '简单的计算器',
        icon: '🧮',
        viewPath: 'views/calculator.html',
        viewMode: 'window',
        devTools: false,
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
        case `hello`:
          log.debug(`执行打招呼动作`);
          return { message: '你好，这是来自示例插件的问候！' };

        case `time`:
          log.debug(`执行时间动作（有自定义视图）`);
          return { success: true };

        case `calculate`:
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

    try {
      // 从文件系统读取HTML文件
      const htmlFilePath = path.join(__dirname, viewPath);
      log.debug(`尝试读取文件: ${htmlFilePath}`);

      if (!fs.existsSync(htmlFilePath)) {
        throw new Error(`视图文件不存在: ${htmlFilePath}`);
      }

      // 读取HTML文件内容
      const html = fs.readFileSync(htmlFilePath, 'utf-8');

      log.info(
        `成功读取视图HTML，文件: ${htmlFilePath}，长度: ${html.length} 字节`
      );
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
