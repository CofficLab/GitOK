// 插件信息
const plugin = {
  name: 'MCP 插件',
  description: '这是一个MCP插件',
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
    return [];
  },
};

// 导出插件
module.exports = plugin;
