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

    return [];
  },
};

// 导出插件对象
module.exports = plugin;
