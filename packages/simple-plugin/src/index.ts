/**
 * 简单插件示例
 */
class SimplePlugin {
  /**
   * 初始化插件
   */
  async initialize() {
    console.log("SimplePlugin: 初始化中...")
  }

  /**
   * 激活插件
   */
  async activate() {
    console.log("SimplePlugin: 已激活")
  }

  /**
   * 停用插件
   */
  async deactivate() {
    console.log("SimplePlugin: 已停用")
  }

  /**
   * 显示欢迎消息
   */
  showWelcomeMessage() {
    return "欢迎使用Simple插件！"
  }
}

// 导出插件实例
export default new SimplePlugin()
