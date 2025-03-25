/**
 * 插件动作接口
 */
export interface SuperAction {
  /**
   * 全局ID
   */
  globalId: string;

  /**
   * 在插件的命名空间中的动作ID
   */
  id: string;

  /**
   * 插件ID
   */
  pluginId: string;

  /**
   * 动作标题
   */
  title: string;

  /**
   * 动作描述
   */
  description?: string;

  /**
   * 动作图标
   */
  icon?: string;

  /**
   * 视图路径
   */
  viewPath?: string;

  /**
   * 视图模式
   */
  viewMode?: 'embedded' | 'window';

  /**
   * 是否启用开发者工具
   */
  devTools?: boolean;
}
