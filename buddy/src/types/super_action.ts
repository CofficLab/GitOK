/**
 * 插件动作接口
 */
export interface SuperAction {
  /**
   * 动作ID
   */
  id: string;

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
