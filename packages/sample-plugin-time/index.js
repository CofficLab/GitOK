/**
 * 示例插件 - 带有页面视图
 * 演示如何创建一个带有主页面的插件
 */

// 插件ID
const PLUGIN_ID = 'sample-plugin-time';

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
    return [];
  },
};

// 导出插件对象
module.exports = plugin;
