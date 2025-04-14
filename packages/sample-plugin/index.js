/**
 * 示例插件 - 带有页面视图
 * 演示如何创建一个带有主页面的插件
 */

// 引入文件系统模块
const fs = require('fs');
const path = require('path');

// 插件ID
const PLUGIN_ID = 'sample-plugin-with-page';

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
  name: '示例页面插件',
  description: '这是一个带有主页面的示例插件',
  version: '1.0.0',
  author: 'Coffic',

  /**
   * 获取插件提供的动作列表
   * @param {object} context 上下文信息
   * @returns {Promise<Array>} 动作列表
   */
  async getActions(context = {}) {
    log.info(`获取动作列表，关键词: "${context.keyword || ''}"`);

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
        id: `${PLUGIN_ID}:page`,
        title: '打开页面',
        description: '打开插件主页面',
        icon: '📄',
        plugin: PLUGIN_ID,
        viewPath: 'page.html',
      },
    ];

    // 如果有关键词，过滤动作
    if (context.keyword) {
      const lowerKeyword = context.keyword.toLowerCase();
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
   * @param {object} action 要执行的动作
   * @returns {Promise<any>} 执行结果
   */
  async executeAction(action) {
    log.info(`执行动作: ${action.id}`);

    // 根据动作ID执行不同的逻辑
    switch (action.id) {
      case `${PLUGIN_ID}:hello`:
        return { message: '你好，这是一个示例插件！' };

      case `${PLUGIN_ID}:page`:
        return { message: '正在打开插件页面...' };

      default:
        throw new Error(`未知的动作: ${action.id}`);
    }
  },

  /**
   * 获取视图内容
   * @param {string} viewPath 视图路径
   * @returns {Promise<string>} 视图HTML内容
   */
  async getViewContent(viewPath) {
    log.info(`获取视图内容: ${viewPath}`);

    try {
      // 构建视图文件的完整路径
      const fullPath = path.join(__dirname, viewPath);
      
      // 检查文件是否存在
      if (!fs.existsSync(fullPath)) {
        throw new Error(`视图文件不存在: ${fullPath}`);
      }

      // 读取视图文件内容
      const content = fs.readFileSync(fullPath, 'utf8');
      return content;
    } catch (error) {
      log.error(`获取视图内容失败: ${error.message}`);
      throw error;
    }
  },
};

// 导出插件对象
module.exports = plugin;
